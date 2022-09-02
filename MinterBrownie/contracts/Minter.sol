// SPDX-License-Identifier
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/utils/Address.sol";
import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";

contract Minter is ERC721{
    using Address for address;
    using Counters for Counters.Counter;

    Counters.Counter public token_counter;
    mapping(uint => address) public ownerOfTokenIds;
     
    constructor() ERC721("People in DALL-E", "DALLE") {}

}