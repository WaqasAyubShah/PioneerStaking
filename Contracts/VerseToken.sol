// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./PioneerAccessControls.sol";

//-----------------------------------------------------------------------------------------| BEGIN CONTRUCTOR AND STATE VARIABLES
contract VreseToken is ERC20 {
    address public admin;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    PioneerAccessControls public accessControls;
    uint256 private _totalSupply = 5000000000 * (10 ** 18);
    uint256 private _minimumSupply = 10000 * (10 ** 18);
    string private _symbol = "VCT";
    string private _name = "VerseToken";

    constructor(PioneerAccessControls accessControls_,) ERC20("VerseToken", "VCT") {
        admin = msg.sender;
    
        _mint(msg.sender, 10000 * (10 ** 18));
    }

    function mint(address to, uint256 amount) public
    {
      
        require(msg.sender == admin, "only admin");
        _mint(to, amount);
    } 
//-----------------------------------------------------------------------------------------| END CONSTRUCTOR, BEGIN BURN LOGIC
    function calculateBurnAmount(uint256 amount) private view returns (uint256) {
        uint256 burnAmount = 0;
        if (_totalSupply > _minimumSupply) {
            burnAmount = (amount / 20);
        }
        return burnAmount;
    }

//-----------------------------------------------------------------------------------------| END BURN LOGIC, BEGIN BURN IMPLEMENNTATION
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 amountToBurn = calculateBurnAmount(amount);
        uint256 amountToTransfer = (amount - amountToBurn);
        _transfer(_msgSender(), recipient, amountToTransfer);
        _burn(msg.sender, amountToBurn);
        assert(_totalSupply >= _minimumSupply);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 amountToBurn = calculateBurnAmount(amount);
        uint256 amountToTransfer = (amount - amountToBurn);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        _transfer(sender, recipient, amountToTransfer);
        _burn(sender, amountToBurn);
        assert(_totalSupply >= _minimumSupply);
        return true;
    }
  
}