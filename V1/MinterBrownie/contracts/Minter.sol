// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/utils/Address.sol";
import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Minter is ERC721URIStorage{
    using Address for address;
    using Counters for Counters.Counter;

    Counters.Counter public token_counter;
    mapping(uint => address) public ownerOfTokenIds;

    constructor(string memory collection_name, string memory collection_symbol) 
        public ERC721(collection_name, collection_symbol) {}

    function mint_dalle(string memory token_uri) public returns(uint256) {
        require(token_counter.current() <= 3); // only could minting in three times
        require(!_exists(token_counter.current()), "This tokenId has already existed");
        // require();
        uint256 token_counter_before_minting = token_counter.current();
        _safeMint(_msgSender(), token_counter.current());
        _setTokenURI(token_counter.current(), token_uri);

        token_counter.increment();
        assert(token_counter.current() == token_counter_before_minting + 1);
        return token_counter.current();
    }
    
    function get_token_id() public view returns(uint256) {
        return token_counter.current();
    }
}

