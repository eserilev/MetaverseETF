// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MetaverseFundToken is ERC20, AccessControl {

    bytes32 public constant ADMIN_ROLE = keccak256(abi.encodePacked("ADMIN_ROLE"));

    constructor() ERC20("Metaverse Fund Token", "MFT") {
    }

    function mint(address account, uint256 amount) public {
        return _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        return _burn(account, amount);
    }
}