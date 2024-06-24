// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {GoodContract} from "../src/GoodContract.sol";
import {BadContract} from "../src/BadContract.sol";

contract ReEntrancy is Test {
    //declare variables for instances of GoodContract and BadContract
    BadContract public badContract;
    GoodContract public goodContract;

    //get two addresses; treat one as an innocent user and the other as an attacker
    //these addresses created by expilcitly casting decimals to addresses
    address innocentUser = address(1);
    address attacker = address(2);

    function setUp() public {
        // Deploy the Good Contract
        goodContract = new GoodContract();

        // Deploy the Bad Contract
        badContract = new BadContract(address(goodContract));

        //set the balances of the attacker and the innocent user to 1 ether
        deal(attacker, 100 ether);
        deal(innocentUser, 100 ether);
    }

    function testAttack() public {
        // First value to deposit (10 ETH)
        uint firstDeposit = 10 ether;

        //for sending the next call will via the innocent user's address
        //prank is a cheatcode in foundry that allows us to impersonate someone
        vm.prank(innocentUser);
        
        // Innocent User deposits 10 ETH into GoodContract
        goodContract.addBalance{value: firstDeposit}();
        
        // Check that at this point the GoodContract's balance is 10 ETH
        assertEq(address(goodContract).balance, firstDeposit);

        //for sending the next call via the attacker's address
        vm.prank(attacker);

        // Attacker calls the `attack` function on BadContract and sends 1 ETH
        badContract.attack{value: 1 ether}();

        // Balance of the GoodContract's address is now zero
        assertEq(address(goodContract).balance, 0);

        // Balance of BadContract is now 11 ETH (10 ETH stolen + 1 ETH from attacker)
        assertEq(address(badContract).balance, 11 ether);
    }
}
