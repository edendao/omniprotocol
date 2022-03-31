// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@rari-capital/solmate/auth/Auth.sol";
import "@rari-capital/solmate/tokens/ERC20.sol";
import "@layerzerolabs/contracts/interfaces/ILayerZeroEndpoint.sol";
import "@layerzerolabs/contracts/interfaces/ILayerZeroReceiver.sol";

import "@protocol/mixins/Pausable.sol";

contract EDN is ERC20, Auth, Pausable, ILayerZeroReceiver {
  ILayerZeroEndpoint public immutable lzEndpoint;
  mapping(uint16 => bytes) public chainContracts;

  constructor(
    address _owner,
    address _authority,
    address _lzEndpoint
  ) ERC20("Eden Dao Note", "EDN", 3) Auth(_owner, Authority(_authority)) {
    lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
  }

  function mint(address _to, uint256 _amount) external requiresAuth {
    _mint(_to, _amount);
  }

  function lzSend(
    uint16 _toChainId,
    address _toAddress,
    uint256 _amount,
    address _zroPaymentAddress, // ZRO payment address
    bytes calldata _adapterParams // txParameters
  ) external payable {
    _burn(msg.sender, _amount);

    lzEndpoint.send{ value: msg.value }(
      _toChainId, // destination chainId
      chainContracts[_toChainId], // destination UA address
      abi.encode(_toAddress, _amount), // abi.encode()'ed bytes
      payable(msg.sender), // refund address (LayerZero will refund any extra gas back to caller of send()
      _zroPaymentAddress, // 'zroPaymentAddress' unused for this mock/example
      _adapterParams
    );
  }

  function lzReceive(
    uint16 _srcChainId,
    bytes calldata _fromAddress,
    uint64, // _nonce
    bytes memory _payload
  ) external {
    require(
      msg.sender == address(lzEndpoint) &&
        _fromAddress.length == chainContracts[_srcChainId].length &&
        keccak256(_fromAddress) == keccak256(chainContracts[_srcChainId]),
      "EDN: Invalid caller for lzReceive"
    );

    (address _toAddress, uint256 _amount) = abi.decode(
      _payload,
      (address, uint256)
    );

    _mint(_toAddress, _amount);
  }

  function estimateSendFee(
    uint16 _toChainId,
    bool _useZro,
    bytes calldata txParameters
  ) external view returns (uint256 nativeFee, uint256 zroFee) {
    return
      lzEndpoint.estimateFees(
        _toChainId,
        address(this),
        bytes(""),
        _useZro,
        txParameters
      );
  }

  function setChainContract(uint16 _dstChainId, address _address)
    external
    requiresAuth
  {
    chainContracts[_dstChainId] = abi.encode(_address);
  }

  function setConfig(
    uint16 _version,
    uint16 _chainId,
    uint256 _configType,
    bytes calldata _config
  ) external requiresAuth {
    lzEndpoint.setConfig(_version, _chainId, _configType, _config);
  }

  function setSendVersion(uint16 version) external requiresAuth {
    lzEndpoint.setSendVersion(version);
  }

  function setReceiveVersion(uint16 version) external requiresAuth {
    lzEndpoint.setReceiveVersion(version);
  }

  function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
    external
    requiresAuth
  {
    lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
  }
}
