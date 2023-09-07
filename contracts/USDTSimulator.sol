//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDTSimulator is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(_msgSender(), 1_000_000_000 * 10**18);
    }

    function transfer(address _to, uint256 _value) public virtual override returns (bool) {
        _transfer(_msgSender(), _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual override returns (bool) {
        uint256 currentAllowance = allowance(_from, _msgSender());
        require(currentAllowance >= _value, "ERC20:EA"); // exceed allowance

        _transfer(_from, _to, _value);
        return true;
    }

}
