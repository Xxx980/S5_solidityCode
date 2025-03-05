pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/ContractWallet.sol";

contract ContractWalletTest is Test {
    MultiSigWallet wallet;

    address owner1 = makeAddr("Owner 1");
    address owner2 = makeAddr("Owner 2");
    address owner3 = makeAddr("Owner 3");

    receive() external payable {}

    function setUp() public {
        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;
        wallet = new MultiSigWallet(owners, 2); // 需要 2 个确认
    }

    function testSubmitProposal() public {
        vm.prank(owner1);
        wallet.submitProposal(address(this), 1 ether, "");
        (address to, uint value, bytes memory data, bool executed, uint confirmationCount) = wallet.getProposal(0);
        assertEq(to, address(this));
        assertEq(value, 1 ether);
        assertEq(data.length, 0);
        assertEq(executed, false);
        assertEq(confirmationCount, 0);
    }

    function testConfirmProposal() public {
        vm.prank(owner1);
        wallet.submitProposal(address(this), 1 ether, "");
        vm.prank(owner2);
        wallet.confirmProposal(0);
        (, , , , uint confirmationCount) = wallet.getProposal(0);
        assertEq(confirmationCount, 1);
    }

    function testExecuteProposal() public {
        vm.deal(address(wallet), 1 ether);
        vm.prank(owner1);
        wallet.submitProposal(address(this), 1 ether, "");
        vm.prank(owner2);
        wallet.confirmProposal(0);
        vm.prank(owner3);
        wallet.confirmProposal(0);
        vm.prank(owner1);
        wallet.executeProposal(0);
        assertEq(address(this).balance, 1 ether);
    }

    function whenConfirmProposalWithInvalidIndex() public {
        vm.prank(owner1);
        wallet.confirmProposal(0); // 未提交提案，应 revert
    }

    function whenExecuteProposalWithInsufficientBalance() public {
        vm.prank(owner1);
        wallet.submitProposal(address(this), 1 ether, "");
        vm.prank(owner2);
        wallet.confirmProposal(0);
        vm.prank(owner3);
        wallet.confirmProposal(0);
        vm.prank(owner1);
        wallet.executeProposal(0); // 余额不足，应 revert
    }
}