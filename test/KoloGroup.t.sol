// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {KoloGroup} from "../src/KoloGroup.sol";

// Mock ERC20 Token for testing
contract MockToken {
    string public name = "Mock Token";
    string public symbol = "MOCK";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function transfer(address to, uint256 amount) public returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function mint(address to, uint256 amount) public {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
}

contract KoloGroupTest is Test {
    KoloGroup public koloGroup;
    MockToken public mockToken;

    // Test accounts
    address public owner;
    address public member1;
    address public member2;
    address public member3;
    address public member4;
    address public member5;

    address[] public members;

    uint256 public constant CONTRIBUTION_AMOUNT = 100e18; // 100 tokens
    uint256 public constant INITIAL_BALANCE = 1000e18; // 1000 tokens per member

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

    function setUp() public {
        // Deploy mock token
        mockToken = new MockToken();

        // Create test accounts
        owner = makeAddr("owner");
        member1 = makeAddr("member1");
        member2 = makeAddr("member2");
        member3 = makeAddr("member3");
        member4 = makeAddr("member4");
        member5 = makeAddr("member5");

        members = [owner, member1, member2, member3, member4, member5];

        // Mint tokens to all members
        for (uint256 i = 0; i < members.length; i++) {
            mockToken.mint(members[i], INITIAL_BALANCE);
        }

        // Owner creates the group
        vm.prank(owner);
        koloGroup = new KoloGroup();
        vm.prank(owner);
        koloGroup.createGroup(CONTRIBUTION_AMOUNT, address(mockToken));
    }

    // ==================== Helper Functions ====================

    function approveAndContribute(address contributor) internal {
        vm.prank(contributor);
        mockToken.approve(address(koloGroup), CONTRIBUTION_AMOUNT);

        vm.prank(contributor);
        koloGroup.contribute(CONTRIBUTION_AMOUNT);
    }

    // ==================== Test: Group Creation ====================

    function test_CreateGroup() public {
        assertEq(koloGroup.owner(), owner);
        assertEq(koloGroup.tokenAddress(), address(mockToken));
        assertEq(koloGroup.contributionAmount(), CONTRIBUTION_AMOUNT);
        assertEq(koloGroup.currentRound(), 1);
        assertEq(koloGroup.payoutIndex(), 0);
        assertEq(koloGroup.getMembersCount(), 1);
        assertTrue(koloGroup.isMember(owner));
    }

    function test_CannotCreateGroupTwice() public {
        vm.prank(owner);
        vm.expectRevert("Group already exists");
        koloGroup.createGroup(CONTRIBUTION_AMOUNT, address(mockToken));
    }

    function test_CannotCreateWithZeroContribution() public {
        address newOwner = makeAddr("newOwner");
        KoloGroup newGroup = new KoloGroup();

        vm.prank(newOwner);
        vm.expectRevert("Contribution amount must be greater than 0");
        newGroup.createGroup(0, address(mockToken));
    }

    // ==================== Test: Members Joining ====================

    function test_MembersJoin() public {
        // Member 1 joins
        vm.prank(member1);
        koloGroup.joinGroup();
        assertEq(koloGroup.getMembersCount(), 2);
        assertTrue(koloGroup.isMember(member1));

        // Member 2 joins
        vm.prank(member2);
        koloGroup.joinGroup();
        assertEq(koloGroup.getMembersCount(), 3);
        assertTrue(koloGroup.isMember(member2));

        // Member 3 joins
        vm.prank(member3);
        koloGroup.joinGroup();
        assertEq(koloGroup.getMembersCount(), 4);

        // Member 4 joins
        vm.prank(member4);
        koloGroup.joinGroup();
        assertEq(koloGroup.getMembersCount(), 5);

        // Member 5 joins
        vm.prank(member5);
        koloGroup.joinGroup();
        assertEq(koloGroup.getMembersCount(), 6);
    }

    function test_CannotJoinTwice() public {
        vm.prank(member1);
        koloGroup.joinGroup();

        vm.prank(member1);
        vm.expectRevert("Already a member");
        koloGroup.joinGroup();
    }

    // ==================== Test: Contributions ====================

    function test_MembersContribute() public {
        // All 5 members join
        vm.prank(member1);
        koloGroup.joinGroup();
        vm.prank(member2);
        koloGroup.joinGroup();
        vm.prank(member3);
        koloGroup.joinGroup();
        vm.prank(member4);
        koloGroup.joinGroup();
        vm.prank(member5);
        koloGroup.joinGroup();

        // All members contribute (including owner)
        approveAndContribute(owner);
        approveAndContribute(member1);
        approveAndContribute(member2);
        approveAndContribute(member3);
        approveAndContribute(member4);
        approveAndContribute(member5);

        // Verify contract balance
        assertEq(
            mockToken.balanceOf(address(koloGroup)),
            CONTRIBUTION_AMOUNT * 6
        );
    }

    function test_CannotContributeTwiceInRound() public {
        vm.prank(member1);
        koloGroup.joinGroup();

        approveAndContribute(owner);

        // Try to contribute again in same round
        vm.prank(owner);
        mockToken.approve(address(koloGroup), CONTRIBUTION_AMOUNT);
        vm.prank(owner);
        vm.expectRevert("Already contributed this round");
        koloGroup.contribute(CONTRIBUTION_AMOUNT);
    }

    function test_WrongContributionAmount() public {
        vm.prank(member1);
        koloGroup.joinGroup();

        vm.prank(owner);
        mockToken.approve(address(koloGroup), CONTRIBUTION_AMOUNT * 2);

        vm.prank(owner);
        vm.expectRevert("Contribution amount must match required amount");
        koloGroup.contribute(CONTRIBUTION_AMOUNT * 2);
    }

    // ==================== Test: Full Cycle (5 Members, 5 Rounds) ====================

    function test_FullCycleAllMembersReceivePayout() public {
        // Setup: 5 members join
        vm.prank(member1);
        koloGroup.joinGroup();
        vm.prank(member2);
        koloGroup.joinGroup();
        vm.prank(member3);
        koloGroup.joinGroup();
        vm.prank(member4);
        koloGroup.joinGroup();
        vm.prank(member5);
        koloGroup.joinGroup();

        // Track payouts
        uint256 expectedPayoutPerRound = CONTRIBUTION_AMOUNT * 6;

        // Track initial balances
        uint256 member1InitialBalance = mockToken.balanceOf(member1);
        uint256 member2InitialBalance = mockToken.balanceOf(member2);
        uint256 member3InitialBalance = mockToken.balanceOf(member3);
        uint256 member4InitialBalance = mockToken.balanceOf(member4);
        uint256 member5InitialBalance = mockToken.balanceOf(member5);
        uint256 ownerInitialBalance = mockToken.balanceOf(owner);

        // ==================== ROUND 1 ====================
        // All members contribute
        approveAndContribute(owner);
        approveAndContribute(member1);
        approveAndContribute(member2);
        approveAndContribute(member3);
        approveAndContribute(member4);
        approveAndContribute(member5);

        // Contract has 600 tokens (100 * 6)
        assertEq(
            mockToken.balanceOf(address(koloGroup)),
            expectedPayoutPerRound
        );

        // Owner triggers payout (Owner should get paid as payoutIndex = 0)
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit PayoutTriggered(owner, expectedPayoutPerRound, 1);
        koloGroup.triggerPayout();

        // Owner receives payout: initial - (1 contribution) + payout
        assertEq(
            mockToken.balanceOf(owner),
            ownerInitialBalance - CONTRIBUTION_AMOUNT + expectedPayoutPerRound
        );
        assertEq(mockToken.balanceOf(address(koloGroup)), 0);

        // ==================== ROUND 2 ====================
        // All members contribute again
        approveAndContribute(owner);
        approveAndContribute(member1);
        approveAndContribute(member2);
        approveAndContribute(member3);
        approveAndContribute(member4);
        approveAndContribute(member5);

        // Member1 gets payout (payoutIndex = 1)
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit PayoutTriggered(member1, expectedPayoutPerRound, 2);
        koloGroup.triggerPayout();

        // Member1: initial - (2 contributions: round 1 + round 2) + (1 payout in round 2)
        assertEq(
            mockToken.balanceOf(member1),
            member1InitialBalance -
                (CONTRIBUTION_AMOUNT * 2) +
                expectedPayoutPerRound
        );
        assertEq(mockToken.balanceOf(address(koloGroup)), 0);

        // ==================== ROUND 3 ====================
        approveAndContribute(owner);
        approveAndContribute(member1);
        approveAndContribute(member2);
        approveAndContribute(member3);
        approveAndContribute(member4);
        approveAndContribute(member5);

        // Member2 gets payout
        vm.prank(owner);
        koloGroup.triggerPayout();

        // Member2: initial - (3 contributions: rounds 1, 2, 3) + (1 payout in round 3)
        assertEq(
            mockToken.balanceOf(member2),
            member2InitialBalance -
                (CONTRIBUTION_AMOUNT * 3) +
                expectedPayoutPerRound
        );

        // ==================== ROUND 4 ====================
        approveAndContribute(owner);
        approveAndContribute(member1);
        approveAndContribute(member2);
        approveAndContribute(member3);
        approveAndContribute(member4);
        approveAndContribute(member5);

        // Member3 gets payout
        vm.prank(owner);
        koloGroup.triggerPayout();

        // Member3: initial - (4 contributions) + (1 payout)
        assertEq(
            mockToken.balanceOf(member3),
            member3InitialBalance -
                (CONTRIBUTION_AMOUNT * 4) +
                expectedPayoutPerRound
        );

        // ==================== ROUND 5 ====================
        approveAndContribute(owner);
        approveAndContribute(member1);
        approveAndContribute(member2);
        approveAndContribute(member3);
        approveAndContribute(member4);
        approveAndContribute(member5);

        // Member4 gets payout
        vm.prank(owner);
        koloGroup.triggerPayout();

        // Member4: initial - (5 contributions) + (1 payout)
        assertEq(
            mockToken.balanceOf(member4),
            member4InitialBalance -
                (CONTRIBUTION_AMOUNT * 5) +
                expectedPayoutPerRound
        );

        // ==================== ROUND 6 ====================
        approveAndContribute(owner);
        approveAndContribute(member1);
        approveAndContribute(member2);
        approveAndContribute(member3);
        approveAndContribute(member4);
        approveAndContribute(member5);

        // Member5 gets payout (last member)
        vm.prank(owner);
        koloGroup.triggerPayout();

        // Member5: initial - (6 contributions) + (1 payout)
        assertEq(
            mockToken.balanceOf(member5),
            member5InitialBalance -
                (CONTRIBUTION_AMOUNT * 6) +
                expectedPayoutPerRound
        );

        // Verify payoutIndex cycles back to 0
        assertEq(koloGroup.payoutIndex(), 0);
    }

    function test_CannotTriggerPayoutWithoutAllContributions() public {
        vm.prank(member1);
        koloGroup.joinGroup();

        // Only owner contributes, member1 doesn't
        approveAndContribute(owner);

        // Owner tries to trigger payout but member1 hasn't contributed
        vm.prank(owner);
        vm.expectRevert("Not all members have contributed");
        koloGroup.triggerPayout();
    }

    function test_CannotTriggerPayoutIfNoFunds() public {
        // Create group with just owner
        // When owner hasn't contributed, allMembersContributed() check fails first
        vm.prank(owner);
        vm.expectRevert("Not all members have contributed");
        koloGroup.triggerPayout();
    }

    function test_AllMembersContributedCheck() public {
        vm.prank(member1);
        koloGroup.joinGroup();
        vm.prank(member2);
        koloGroup.joinGroup();

        assertFalse(koloGroup.allMembersContributed());

        approveAndContribute(owner);
        assertFalse(koloGroup.allMembersContributed());

        approveAndContribute(member1);
        assertFalse(koloGroup.allMembersContributed());

        approveAndContribute(member2);
        assertTrue(koloGroup.allMembersContributed());
    }

    function test_CurrentRoundIncrementsAfterPayout() public {
        vm.prank(member1);
        koloGroup.joinGroup();
        vm.prank(member2);
        koloGroup.joinGroup();

        assertEq(koloGroup.currentRound(), 1);

        // Round 1: All contribute and payout
        approveAndContribute(owner);
        approveAndContribute(member1);
        approveAndContribute(member2);

        vm.prank(owner);
        koloGroup.triggerPayout();
        assertEq(koloGroup.currentRound(), 2);

        // Round 2: All contribute and payout
        approveAndContribute(owner);
        approveAndContribute(member1);
        approveAndContribute(member2);

        vm.prank(owner);
        koloGroup.triggerPayout();
        assertEq(koloGroup.currentRound(), 3);
    }
}
