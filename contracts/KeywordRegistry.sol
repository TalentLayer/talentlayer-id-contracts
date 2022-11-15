// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * The KeywordRegistry manages the storage and retreival of keywords.
 */
contract KeywordRegistry is Ownable{
	
	string[] keywords;
	
	event KeywordCreated(uint256 id, string keyword);
	
	uint256 count = 0;

	constructor() public {}

	function addKeyword (string memory keyword) external onlyOwner {
		uint256 id = getKeywordID(keyword);

		if(id == count){
			keywords.push(keyword);
			count++;
		}

		emit KeywordCreated(id, keyword);
	}

	function updateKeywordList (string[] memory _keywords) external onlyOwner {
		keywords = _keywords;
	}

	function getKeywordID(string memory keyword) public view returns (uint256 id) {
		for(uint256 i = 0; i < count; i++){
			if (keccak256(abi.encodePacked(keywords[i])) == keccak256(abi.encodePacked(keyword))){
				return i;
			}
		}
		return count;
	}
}
