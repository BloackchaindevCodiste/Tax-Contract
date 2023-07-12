// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "./interfaces.sol";

contract WhiteHatDAOToken is
    ERC20,
    ERC20Burnable,
    ERC20Snapshot,
    Ownable,
    ERC20Permit,
    ERC20Votes
{
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;
    uint256 private _upperLimmitOfTaxPercentage = 1000;
    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public restrictedUser;
    mapping(address => bool) public uniswapV2Pair;
    uint256 public buyTax;
    uint256 public sellTax;

    constructor(
        address _router
    ) ERC20("White Hat DAO Token", "WHDT") ERC20Permit("WhiteHatDAOToken") {
        uniswapV2Router = IUniswapV2Router02(_router);
        address pairWithWETH = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair[pairWithWETH] = true;
        isExcludedFromFee[owner()] = true;
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function percent(
        uint256 amount,
        uint256 fraction
    ) public pure virtual returns (uint256) {
        return ((amount).mul(fraction)).div(10000);
    }

    function decimals() public view virtual override returns (uint8) {
        return 10;
    }

    function setSellTax(uint256 percentage) public onlyOwner {
        require(
            _upperLimmitOfTaxPercentage >= percentage,
            "Limit exceed(can not set more than 10 percent)"
        );
        sellTax = percentage;
    }

    function setBuyTax(uint256 percentage) public onlyOwner {
        require(
            _upperLimmitOfTaxPercentage >= percentage,
            "Limit exceed(can not set more than 10 percent)"
        );
        buyTax = percentage;
    }

    function excludeFromFee(address[] calldata account) public onlyOwner {
        for (uint256 i = 0; i < account.length; i++) {
            isExcludedFromFee[account[i]] = true;
        }
    }

    function includeInFee(address[] calldata account) public onlyOwner {
        for (uint256 i = 0; i < account.length; i++) {
            isExcludedFromFee[account[i]] = false;
        }
    }

    function restrictUser(address[] calldata account) public onlyOwner {
        for (uint256 i = 0; i < account.length; i++) {
            restrictedUser[account[i]] = true;
        }
    }

    function removeFromRestrictedUser(address[] calldata account) public onlyOwner {
        for (uint256 i = 0; i < account.length; i++) {
            restrictedUser[account[i]] = false;
        }
    }

    function addPairContractAddress(address pairAddress) public onlyOwner {
        uniswapV2Pair[pairAddress] = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = balanceOf(from);
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        require(
            !(restrictedUser[from] || restrictedUser[to]),
            "You are restricted for transfer"
        );
        if (
            to != address(0) &&
            !(isExcludedFromFee[from] || isExcludedFromFee[to]) &&
            uniswapV2Pair[from] == true
        ) {
            uint256 burnamount = percent(amount, buyTax);
            _burn(from, burnamount);
            super._transfer(from, to, amount - burnamount);
        } else if (
            to != address(0) &&
            !(isExcludedFromFee[from] || isExcludedFromFee[to]) &&
            uniswapV2Pair[to] == true
        ) {
            uint256 burnamount = percent(amount, sellTax);
                _burn(from, burnamount);
                super._transfer(from, to, amount - burnamount);
        } else {
            super._transfer(from, to, amount);
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function burn( uint256 amount) public override onlyOwner {
        super.burn( amount);
    }
    
    function _burn(
        address account,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}
