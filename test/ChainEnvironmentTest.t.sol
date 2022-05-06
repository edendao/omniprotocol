// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {DSTestPlus} from "@solmate/test/utils/DSTestPlus.sol";

import {LZEndpointMock} from "@test/mocks/LZEndpointMock.sol";

import {IOmninote} from "@protocol/interfaces/IOmninote.sol";
import {ERC20} from "@protocol/mixins/ERC20.sol";
import {Comptroller} from "@protocol/Comptroller.sol";

import {Note} from "@protocol/Note.sol";
import {Omnibridge} from "@protocol/Omnibridge.sol";
import {Omnicast} from "@protocol/Omnicast.sol";
import {Passport} from "@protocol/Passport.sol";
import {Reserve} from "@protocol/Reserve.sol";
import {Space} from "@protocol/Space.sol";

contract MockERC20 is IOmninote, ERC20 {
  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) {
    __initERC20(_name, _symbol, _decimals);
  }

  function mintTo(address receiver, uint256 amount) public {
    _mint(receiver, amount);
  }

  function burnFrom(address account, uint256 amount) public {
    _burn(account, amount);
  }

  function remoteContract(uint16) public pure returns (bytes memory) {
    return bytes("");
  }
}

contract ChainEnvironmentTest is DSTestPlus {
  address public myAddress = address(this);
  address public ownerAddress = hevm.addr(42);

  uint16 public currentChainId = uint16(block.chainid);

  MockERC20 public dai = new MockERC20("DAI", "DAI", 18);
  LZEndpointMock public layerZeroEndpoint = new LZEndpointMock(currentChainId);

  Comptroller public comptroller = new Comptroller();

  Omnicast internal omnicast =
    new Omnicast(address(layerZeroEndpoint), address(comptroller));
  Space public space =
    new Space(address(comptroller), address(omnicast), currentChainId);
  Passport public passport =
    new Passport(address(comptroller), address(omnicast));

  Note public noteImplementation = new Note();
  Reserve public reserveImplementation = new Reserve();
  Omnibridge public bridge =
    new Omnibridge(
      address(layerZeroEndpoint),
      address(comptroller),
      address(noteImplementation),
      address(reserveImplementation)
    );

  function setUp() public virtual {
    comptroller.initialize(address(0), abi.encode(myAddress));
    omnicast.setContracts(address(space), address(passport));
  }
}
