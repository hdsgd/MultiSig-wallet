// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts@4.9/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.9/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts@4.9/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts@4.9/access/Ownable.sol";

contract MyToken is ERC20, ERC20Burnable, ERC20Pausable, Ownable {
    constructor()
        ERC20("TokenTeste", "Teste")
    {}

    function pause() public onlyOwner {
        _pause();
    }

    function getPauseData() public pure returns (bytes memory) {
        return abi.encodeWithSignature("pause()");
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getUnPauseData() public pure returns (bytes memory) {
        return abi.encodeWithSignature("unpause()");
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    } 

    function getMintData(address _to, uint256 _amount) public pure returns (bytes memory) {
        return abi.encodeWithSignature("mint(address,uint256)", _to , _amount);
    }  

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(_from, _to, _amount);
    }
}