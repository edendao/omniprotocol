// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IOmninote} from "@protocol/interfaces/IOmninote.sol";
import {ERC20} from "@protocol/mixins/ERC20.sol";
import {Omnichain} from "@protocol/mixins/Omnichain.sol";
import {Cloneable} from "@protocol/mixins/Cloneable.sol";

import {Comptroller} from "@protocol/Comptroller.sol";
import {Note} from "@protocol/Note.sol";
import {Reserve} from "@protocol/Reserve.sol";

contract Omnibridge is Omnichain {
  address public noteImplementation;
  address public reserveImplementation;

  constructor(
    address _lzEndpoint,
    address _comptroller,
    address _noteImplementation,
    address _reserveImplementation
  ) {
    __initOmnichain(_lzEndpoint);
    __initComptrolled(_comptroller);

    noteImplementation = _noteImplementation;
    reserveImplementation = _reserveImplementation;
  }

  event CreateComptroller(address indexed owner, address comptroller);

  function createComptroller(address _owner) external returns (Comptroller c) {
    c = Comptroller(
      payable(createClone(comptrollerAddress(), abi.encode(_owner)))
    );
    emit CreateComptroller(_owner, address(c));
  }

  event CreateNote(
    address indexed comptroller,
    string name,
    string symbol,
    uint8 decimals
  );

  function createNote(
    address _comptroller,
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) external returns (Note n) {
    n = Note(
      createClone(
        noteImplementation,
        abi.encode(_comptroller, _name, _symbol, _decimals)
      )
    );
    emit CreateNote(_comptroller, _name, _symbol, _decimals);
  }

  event CreateReserve(
    address comptroller,
    address asset,
    string name,
    string symbol,
    uint8 decimals
  );

  function createReserve(
    address _comptroller,
    address _asset,
    string memory _name,
    string memory _symbol
  ) external returns (Reserve r) {
    r = Reserve(
      createClone(
        reserveImplementation,
        abi.encode(_comptroller, _asset, _name, _symbol)
      )
    );
    emit CreateReserve(_comptroller, _asset, _name, _symbol, r.decimals());
  }

  function createClone(address target, bytes memory params)
    internal
    returns (address result)
  {
    bytes20 targetBytes = bytes20(target);
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let clone := mload(0x40)
      mstore(
        clone,
        0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
      )
      mstore(add(clone, 0x14), targetBytes)
      mstore(
        add(clone, 0x28),
        0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
      )
      result := create(0, clone, 0x37)
    }
    Cloneable(result).initialize(comptrollerAddress(), params);
  }

  event SendNote(
    uint16 indexed toChainId,
    uint64 nonce,
    address indexed noteAddress,
    address indexed fromAddress,
    bytes toAddress,
    uint256 amount
  );

  function sendNote(
    address noteAddress,
    uint256 amount,
    uint16 toChainId,
    bytes calldata toAddress,
    address lzPaymentAddress,
    bytes calldata lzTransactionParams
  ) external payable {
    IOmninote note = IOmninote(noteAddress);
    note.burnFrom(msg.sender, amount);

    lzSend(
      toChainId,
      abi.encode(note.remoteNote(toChainId), toAddress, amount),
      lzPaymentAddress,
      lzTransactionParams
    );

    emit SendNote(
      toChainId,
      lzEndpoint.getOutboundNonce(toChainId, address(this)),
      noteAddress,
      msg.sender,
      toAddress,
      amount
    );
  }

  // Receive notes from omnispace
  event ReceiveNote(
    uint16 indexed fromChainId,
    uint64 nonce,
    address indexed noteAddress,
    address indexed toAddress,
    uint256 amount
  );

  function receiveMessage(
    uint16 fromChainId,
    bytes calldata, // _fromContractAddress,
    uint64 nonce,
    bytes calldata payload
  ) internal override {
    (bytes memory noteAddressB, bytes memory toAddressB, uint256 amount) = abi
      .decode(payload, (bytes, bytes, uint256));
    address noteAddress = addressFromPackedBytes(noteAddressB);
    address toAddress = addressFromPackedBytes(toAddressB);

    IOmninote(noteAddress).mintTo(toAddress, amount);

    emit ReceiveNote(fromChainId, nonce, noteAddress, toAddress, amount);
  }

  // Estimate LayerZero gas to pass with .sendNote{value: gasFees}
  function estimateLayerZeroGas(
    uint16 toChainId,
    bool useZRO,
    bytes calldata lzTransactionParams
  ) public view returns (uint256 gasFees, uint256 lzFees) {
    (gasFees, lzFees) = lzEstimateSendGas(
      toChainId,
      abi.encode(bytes20(""), bytes20(""), 0),
      useZRO,
      lzTransactionParams
    );
  }
}
