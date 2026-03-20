// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract KoloGroup {
    // State variables
    address[] public members;
    uint256 public contributionAmount;
    uint256 public currentRound;
    uint256 public payoutIndex;

    address public owner;
    address public tokenAddress; // ERC20 token address
    bool private locked; // Reentrancy guard

    // Mapping to track member status and contributions
    mapping(address => bool) public isMember;
    mapping(address => uint256) public totalContributions;
    mapping(uint256 => mapping(address => bool)) public hasContributedInRound;
    mapping(address => uint256) public memberBalance;

    // Events
    event GroupCreated(address indexed owner, uint256 contributionAmount);
    event MemberJoined(address indexed member, uint256 membersCount);
    event ContributionReceived(
        address indexed member,
        uint256 amount,
        uint256 round
    );
    event PayoutTriggered(
        address indexed recipient,
        uint256 amount,
        uint256 round
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event MemberRemoved(address indexed member);
    event EmergencyWithdrawal(address indexed member, uint256 amount);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyMember() {
        require(
            isMember[msg.sender],
            "Only group members can call this function"
        );
        _;
    }

    /// @notice Reentrancy guard modifier
    modifier nonReentrant() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

    /// @notice Create a new Kolo group
    /// @param _contributionAmount The amount each member must contribute per round
    /// @param _tokenAddress The address of the ERC20 token to use
    function createGroup(
        uint256 _contributionAmount,
        address _tokenAddress
    ) external {
        require(
            _contributionAmount > 0,
            "Contribution amount must be greater than 0"
        );
        require(_tokenAddress != address(0), "Invalid token address");
        require(owner == address(0), "Group already exists");
        require(msg.sender != address(0), "Invalid caller");

        owner = msg.sender;
        tokenAddress = _tokenAddress;
        contributionAmount = _contributionAmount;
        currentRound = 1;
        payoutIndex = 0;

        // Add owner as first member
        members.push(msg.sender);
        isMember[msg.sender] = true;

        emit GroupCreated(msg.sender, _contributionAmount);
    }

    /// @notice Join an existing Kolo group
    function joinGroup() external {
        require(msg.sender != address(0), "Invalid address");
        require(!isMember[msg.sender], "Already a member");
        require(members.length > 0, "Group does not exist");

        members.push(msg.sender);
        isMember[msg.sender] = true;

        emit MemberJoined(msg.sender, members.length);
    }

    /// @notice Contribute to the current round
    function contribute(uint256 amount) external onlyMember {
        require(
            amount == contributionAmount,
            "Contribution amount must match required amount"
        );
        require(
            !hasContributedInRound[currentRound][msg.sender],
            "Already contributed this round"
        );

        // Transfer tokens from member to contract
        bool success = IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(success, "Token transfer failed");

        hasContributedInRound[currentRound][msg.sender] = true;
        totalContributions[msg.sender] += amount;

        emit ContributionReceived(msg.sender, amount, currentRound);
    }

    /// @notice Trigger payout to the next member in line
    function triggerPayout() external onlyOwner nonReentrant {
        require(members.length > 0, "No members in group");

        // Verify all members have contributed this round
        require(allMembersContributed(), "Not all members have contributed");

        address recipient = members[payoutIndex];
        uint256 totalPool = IERC20(tokenAddress).balanceOf(address(this));

        require(totalPool > 0, "No funds available for payout");
        require(recipient != address(0), "Invalid recipient");

        // State changes before external call (checks-effects-interactions)
        uint256 roundNumber = currentRound;
        payoutIndex = (payoutIndex + 1) % members.length;
        currentRound++;

        // Transfer tokens to recipient (external interaction last)
        bool success = IERC20(tokenAddress).transfer(recipient, totalPool);
        require(success, "Token transfer failed");

        emit PayoutTriggered(recipient, totalPool, roundNumber);
    }

    /// @notice Get total number of members
    function getMembersCount() external view returns (uint256) {
        return members.length;
    }

    /// @notice Get all members
    function getMembers() external view returns (address[] memory) {
        return members;
    }

    /// @notice Check if all members have contributed in current round
    function allMembersContributed() public view returns (bool) {
        for (uint256 i = 0; i < members.length; i++) {
            if (!hasContributedInRound[currentRound][members[i]]) {
                return false;
            }
        }
        return true;
    }

    /// @notice Transfer ownership to a new address
    /// @param newOwner The address of the new owner
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(newOwner != owner, "Already the owner");
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    /// @notice Remove a member from the group (for fairness)
    /// @param member The address of the member to remove
    function removeMember(address member) external onlyOwner {
        require(member != address(0), "Invalid member address");
        require(isMember[member], "Not a member");
        require(member != owner, "Cannot remove owner");
        require(
            !hasContributedInRound[currentRound][member],
            "Cannot remove member who has contributed this round"
        );

        isMember[member] = false;

        // Remove from members array
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == member) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }

        // Adjust payoutIndex if necessary
        if (payoutIndex >= members.length && members.length > 0) {
            payoutIndex = 0;
        }

        emit MemberRemoved(member);
    }

    /// @notice Emergency withdrawal for members (in case of contract issues)
    function emergencyWithdraw() external onlyMember nonReentrant {
        uint256 balance = memberBalance[msg.sender];
        require(balance > 0, "No balance to withdraw");

        memberBalance[msg.sender] = 0;
        bool success = IERC20(tokenAddress).transfer(msg.sender, balance);
        require(success, "Token transfer failed");

        emit EmergencyWithdrawal(msg.sender, balance);
    }

    /// @notice Get contract token balance
    function getTokenBalance() external view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
}
