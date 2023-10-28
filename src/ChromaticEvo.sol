
// File: @openzeppelin/contracts/utils/Base64.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/Base64.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// File: @thirdweb-dev/contracts/extension/BatchMintMetadata.sol


pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  @title   Batch-mint Metadata
 *  @notice  The `BatchMintMetadata` is a contract extension for any base NFT contract. It lets the smart contract
 *           using this extension set metadata for `n` number of NFTs all at once. This is enabled by storing a single
 *           base URI for a batch of `n` NFTs, where the metadata for each NFT in a relevant batch is `baseURI/tokenId`.
 */

contract BatchMintMetadata {
    /// @dev Largest tokenId of each batch of tokens with the same baseURI.
    uint256[] private batchIds;

    /// @dev Mapping from id of a batch of tokens => to base URI for the respective batch of tokens.
    mapping(uint256 => string) private baseURI;

    /// @dev Mapping from id of a batch of tokens => to whether the base URI for the respective batch of tokens is frozen.
    mapping(uint256 => bool) public batchFrozen;

    /// @dev This event emits when the metadata of all tokens are frozen.
    /// While not currently supported by marketplaces, this event allows
    /// future indexing if desired.
    event MetadataFrozen();

    // @dev This event emits when the metadata of a range of tokens is updated.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /**
     *  @notice         Returns the count of batches of NFTs.
     *  @dev            Each batch of tokens has an in ID and an associated `baseURI`.
     *                  See {batchIds}.
     */
    function getBaseURICount() public view returns (uint256) {
        return batchIds.length;
    }

    /**
     *  @notice         Returns the ID for the batch of tokens at the given index.
     *  @dev            See {getBaseURICount}.
     *  @param _index   Index of the desired batch in batchIds array.
     */
    function getBatchIdAtIndex(uint256 _index) public view returns (uint256) {
        if (_index >= getBaseURICount()) {
            revert("Invalid index");
        }
        return batchIds[_index];
    }

    /// @dev Returns the id for the batch of tokens the given tokenId belongs to.
    function _getBatchId(uint256 _tokenId) internal view returns (uint256 batchId, uint256 index) {
        uint256 numOfTokenBatches = getBaseURICount();
        uint256[] memory indices = batchIds;

        for (uint256 i = 0; i < numOfTokenBatches; i += 1) {
            if (_tokenId < indices[i]) {
                index = i;
                batchId = indices[i];

                return (batchId, index);
            }
        }

        revert("Invalid tokenId");
    }

    /// @dev Returns the baseURI for a token. The intended metadata URI for the token is baseURI + tokenId.
    function _getBaseURI(uint256 _tokenId) internal view returns (string memory) {
        uint256 numOfTokenBatches = getBaseURICount();
        uint256[] memory indices = batchIds;

        for (uint256 i = 0; i < numOfTokenBatches; i += 1) {
            if (_tokenId < indices[i]) {
                return baseURI[indices[i]];
            }
        }
        revert("Invalid tokenId");
    }

    /// @dev returns the starting tokenId of a given batchId.
    function _getBatchStartId(uint256 _batchID) internal view returns (uint256) {
        uint256 numOfTokenBatches = getBaseURICount();
        uint256[] memory indices = batchIds;

        for (uint256 i = 0; i < numOfTokenBatches; i++) {
            if (_batchID == indices[i]) {
                if (i > 0) {
                    return indices[i - 1];
                }
                return 0;
            }
        }
        revert("Invalid batchId");
    }

    /// @dev Sets the base URI for the batch of tokens with the given batchId.
    function _setBaseURI(uint256 _batchId, string memory _baseURI) internal {
        require(!batchFrozen[_batchId], "Batch frozen");
        baseURI[_batchId] = _baseURI;
        emit BatchMetadataUpdate(_getBatchStartId(_batchId), _batchId);
    }

    /// @dev Freezes the base URI for the batch of tokens with the given batchId.
    function _freezeBaseURI(uint256 _batchId) internal {
        string memory baseURIForBatch = baseURI[_batchId];
        require(bytes(baseURIForBatch).length > 0, "Invalid batch");
        batchFrozen[_batchId] = true;
        emit MetadataFrozen();
    }

    /// @dev Mints a batch of tokenIds and associates a common baseURI to all those Ids.
    function _batchMintMetadata(
        uint256 _startId,
        uint256 _amountToMint,
        string memory _baseURIForTokens
    ) internal returns (uint256 nextTokenIdToMint, uint256 batchId) {
        batchId = _startId + _amountToMint;
        nextTokenIdToMint = batchId;

        batchIds.push(batchId);

        baseURI[batchId] = _baseURIForTokens;
    }
}

// File: @thirdweb-dev/contracts/extension/interface/IOwnable.sol


pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *  information about who the contract's owner is.
 */

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
}

// File: @thirdweb-dev/contracts/extension/Ownable.sol


pragma solidity ^0.8.0;

/// @author thirdweb


/**
 *  @title   Ownable
 *  @notice  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *           information about who the contract's owner is.
 */

abstract contract Ownable is IOwnable {
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev Reverts if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert("Not authorized");
        }
        _;
    }

    /**
     *  @notice Returns the owner of the contract.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     *  @notice Lets an authorized wallet set a new owner for the contract.
     *  @param _newOwner The address to set as the new owner of the contract.
     */
    function setOwner(address _newOwner) external override {
        if (!_canSetOwner()) {
            revert("Not authorized");
        }
        _setupOwner(_newOwner);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupOwner(address _newOwner) internal {
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual returns (bool);
}

// File: @thirdweb-dev/contracts/extension/interface/IMulticall.sol


pragma solidity ^0.8.0;

/// @author thirdweb

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
interface IMulticall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);
}

// File: @thirdweb-dev/contracts/extension/interface/IContractMetadata.sol


pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  Thirdweb's `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *  for you contract.
 *
 *  Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

interface IContractMetadata {
    /// @dev Returns the metadata URI of the contract.
    function contractURI() external view returns (string memory);

    /**
     *  @dev Sets contract URI for the storefront-level metadata of the contract.
     *       Only module admin can call this function.
     */
    function setContractURI(string calldata _uri) external;

    /// @dev Emitted when the contract URI is updated.
    event ContractURIUpdated(string prevURI, string newURI);
}

// File: @thirdweb-dev/contracts/extension/ContractMetadata.sol


pragma solidity ^0.8.0;

/// @author thirdweb


/**
 *  @title   Contract Metadata
 *  @notice  Thirdweb's `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *           for you contract.
 *           Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

abstract contract ContractMetadata is IContractMetadata {
    /// @notice Returns the contract metadata URI.
    string public override contractURI;

    /**
     *  @notice         Lets a contract admin set the URI for contract-level metadata.
     *  @dev            Caller should be authorized to setup contractURI, e.g. contract admin.
     *                  See {_canSetContractURI}.
     *                  Emits {ContractURIUpdated Event}.
     *
     *  @param _uri     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     */
    function setContractURI(string memory _uri) external override {
        if (!_canSetContractURI()) {
            revert("Not authorized");
        }

        _setupContractURI(_uri);
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function _setupContractURI(string memory _uri) internal {
        string memory prevURI = contractURI;
        contractURI = _uri;

        emit ContractURIUpdated(prevURI, _uri);
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual returns (bool);
}

// File: @thirdweb-dev/contracts/eip/interface/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-165).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @thirdweb-dev/contracts/eip/interface/IERC2981.sol


pragma solidity ^0.8.0;


/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: @thirdweb-dev/contracts/extension/interface/IRoyalty.sol


pragma solidity ^0.8.0;

/// @author thirdweb


/**
 *  Thirdweb's `Royalty` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  the recipient of royalty fee and the royalty fee basis points, and lets the inheriting contract perform conditional logic
 *  that uses information about royalty fees, if desired.
 *
 *  The `Royalty` contract is ERC2981 compliant.
 */

interface IRoyalty is IERC2981 {
    struct RoyaltyInfo {
        address recipient;
        uint256 bps;
    }

    /// @dev Returns the royalty recipient and fee bps.
    function getDefaultRoyaltyInfo() external view returns (address, uint16);

    /// @dev Lets a module admin update the royalty bps and recipient.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external;

    /// @dev Lets a module admin set the royalty recipient for a particular token Id.
    function setRoyaltyInfoForToken(
        uint256 tokenId,
        address recipient,
        uint256 bps
    ) external;

    /// @dev Returns the royalty recipient for a particular token Id.
    function getRoyaltyInfoForToken(uint256 tokenId) external view returns (address, uint16);

    /// @dev Emitted when royalty info is updated.
    event DefaultRoyalty(address indexed newRoyaltyRecipient, uint256 newRoyaltyBps);

    /// @dev Emitted when royalty recipient for tokenId is set
    event RoyaltyForToken(uint256 indexed tokenId, address indexed royaltyRecipient, uint256 royaltyBps);
}

// File: @thirdweb-dev/contracts/extension/Royalty.sol


pragma solidity ^0.8.0;

/// @author thirdweb


/**
 *  @title   Royalty
 *  @notice  Thirdweb's `Royalty` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           the recipient of royalty fee and the royalty fee basis points, and lets the inheriting contract perform conditional logic
 *           that uses information about royalty fees, if desired.
 *
 *  @dev     The `Royalty` contract is ERC2981 compliant.
 */

abstract contract Royalty is IRoyalty {
    /// @dev The (default) address that receives all royalty value.
    address private royaltyRecipient;

    /// @dev The (default) % of a sale to take as royalty (in basis points).
    uint16 private royaltyBps;

    /// @dev Token ID => royalty recipient and bps for token
    mapping(uint256 => RoyaltyInfo) private royaltyInfoForToken;

    /**
     *  @notice   View royalty info for a given token and sale price.
     *  @dev      Returns royalty amount and recipient for `tokenId` and `salePrice`.
     *  @param tokenId          The tokenID of the NFT for which to query royalty info.
     *  @param salePrice        Sale price of the token.
     *
     *  @return receiver        Address of royalty recipient account.
     *  @return royaltyAmount   Royalty amount calculated at current royaltyBps value.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        (address recipient, uint256 bps) = getRoyaltyInfoForToken(tokenId);
        receiver = recipient;
        royaltyAmount = (salePrice * bps) / 10_000;
    }

    /**
     *  @notice          View royalty info for a given token.
     *  @dev             Returns royalty recipient and bps for `_tokenId`.
     *  @param _tokenId  The tokenID of the NFT for which to query royalty info.
     */
    function getRoyaltyInfoForToken(uint256 _tokenId) public view override returns (address, uint16) {
        RoyaltyInfo memory royaltyForToken = royaltyInfoForToken[_tokenId];

        return
            royaltyForToken.recipient == address(0)
                ? (royaltyRecipient, uint16(royaltyBps))
                : (royaltyForToken.recipient, uint16(royaltyForToken.bps));
    }

    /**
     *  @notice Returns the defualt royalty recipient and BPS for this contract's NFTs.
     */
    function getDefaultRoyaltyInfo() external view override returns (address, uint16) {
        return (royaltyRecipient, uint16(royaltyBps));
    }

    /**
     *  @notice         Updates default royalty recipient and bps.
     *  @dev            Caller should be authorized to set royalty info.
     *                  See {_canSetRoyaltyInfo}.
     *                  Emits {DefaultRoyalty Event}; See {_setupDefaultRoyaltyInfo}.
     *
     *  @param _royaltyRecipient   Address to be set as default royalty recipient.
     *  @param _royaltyBps         Updated royalty bps.
     */
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external override {
        if (!_canSetRoyaltyInfo()) {
            revert("Not authorized");
        }

        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
    }

    /// @dev Lets a contract admin update the default royalty recipient and bps.
    function _setupDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) internal {
        if (_royaltyBps > 10_000) {
            revert("Exceeds max bps");
        }

        royaltyRecipient = _royaltyRecipient;
        royaltyBps = uint16(_royaltyBps);

        emit DefaultRoyalty(_royaltyRecipient, _royaltyBps);
    }

    /**
     *  @notice         Updates default royalty recipient and bps for a particular token.
     *  @dev            Sets royalty info for `_tokenId`. Caller should be authorized to set royalty info.
     *                  See {_canSetRoyaltyInfo}.
     *                  Emits {RoyaltyForToken Event}; See {_setupRoyaltyInfoForToken}.
     *
     *  @param _recipient   Address to be set as royalty recipient for given token Id.
     *  @param _bps         Updated royalty bps for the token Id.
     */
    function setRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) external override {
        if (!_canSetRoyaltyInfo()) {
            revert("Not authorized");
        }

        _setupRoyaltyInfoForToken(_tokenId, _recipient, _bps);
    }

    /// @dev Lets a contract admin set the royalty recipient and bps for a particular token Id.
    function _setupRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) internal {
        if (_bps > 10_000) {
            revert("Exceeds max bps");
        }

        royaltyInfoForToken[_tokenId] = RoyaltyInfo({ recipient: _recipient, bps: _bps });

        emit RoyaltyForToken(_tokenId, _recipient, _bps);
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view virtual returns (bool);
}

// File: @thirdweb-dev/contracts/eip/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @thirdweb-dev/contracts/lib/TWStrings.sol


pragma solidity ^0.8.0;

/// @author thirdweb

/**
 * @dev String operations.
 */
library TWStrings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @thirdweb-dev/contracts/external-deps/openzeppelin/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @thirdweb-dev/contracts/lib/TWAddress.sol


pragma solidity ^0.8.0;

/// @author thirdweb

/**
 * @dev Collection of functions related to the address type
 */
library TWAddress {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * [EIP1884](https://eips.ethereum.org/EIPS/eip-1884) increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @thirdweb-dev/contracts/extension/Multicall.sol


pragma solidity ^0.8.0;

/// @author thirdweb



/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
contract Multicall is IMulticall {
    /**
     *  @notice Receives and executes a batch of function calls on this contract.
     *  @dev Receives and executes a batch of function calls on this contract.
     *
     *  @param data The bytes data that makes up the batch of function calls to execute.
     *  @return results The bytes data that makes up the result of the batch of function calls executed.
     */
    function multicall(bytes[] calldata data) external virtual override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = TWAddress.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// File: @thirdweb-dev/contracts/eip/interface/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @thirdweb-dev/contracts/eip/interface/IERC721Metadata.sol


pragma solidity ^0.8.0;

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
/* is ERC721 */
interface IERC721Metadata {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// File: @thirdweb-dev/contracts/eip/interface/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: @thirdweb-dev/contracts/eip/interface/IERC721A.sol


// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;



/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A is IERC721, IERC721Metadata {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}

// File: @thirdweb-dev/contracts/eip/ERC721AVirtualApprove.sol


// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

////////// CHANGELOG: turn `approve` to virtual //////////







/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721A {
    using TWAddress for address;
    using TWStrings for uint256;

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    TokenOwnership memory ownership = _ownerships[curr];
                    if (!ownership.burned) {
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                        // Invariant:
                        // There will always be an ownership that has an address and is not burned
                        // before an ownership that does not have an address and is not burned.
                        // Hence, curr will not underflow.
                        while (true) {
                            curr--;
                            ownership = _ownerships[curr];
                            if (ownership.addr != address(0)) {
                                return ownership;
                            }
                        }
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner)
            if (!isApprovedForAll(owner, _msgSender())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract())
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex < end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// File: @thirdweb-dev/contracts/base/ERC721Base.sol


pragma solidity ^0.8.0;

/// @author thirdweb








/**
 *  The `ERC721Base` smart contract implements the ERC721 NFT standard, along with the ERC721A optimization to the standard.
 *  It includes the following additions to standard ERC721 logic:
 *
 *      - Ability to mint NFTs via the provided `mint` function.
 *
 *      - Contract metadata for royalty support on platforms such as OpenSea that use
 *        off-chain information to distribute roaylties.
 *
 *      - Ownership of the contract, with the ability to restrict certain functions to
 *        only be called by the contract's owner.
 *
 *      - Multicall capability to perform multiple actions atomically
 *
 *      - EIP 2981 compliance for royalty support on NFT marketplaces.
 */

contract ERC721Base is ERC721A, ContractMetadata, Multicall, Ownable, Royalty, BatchMintMetadata {
    using TWStrings for uint256;

    /*//////////////////////////////////////////////////////////////
                            Mappings
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => string) private fullURI;

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract during construction.
     *
     * @param _defaultAdmin     The default admin of the contract.
     * @param _name             The name of the contract.
     * @param _symbol           The symbol of the contract.
     * @param _royaltyRecipient The address to receive royalties.
     * @param _royaltyBps       The royalty basis points to be charged. Max = 10000 (10000 = 100%, 1000 = 10%)
     */
    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) ERC721A(_name, _symbol) {
        _setupOwner(_defaultAdmin);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC165 Logic
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See ERC165: https://eips.ethereum.org/EIPS/eip-165
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId == type(IERC2981).interfaceId; // ERC165 ID for ERC2981
    }

    /*//////////////////////////////////////////////////////////////
                        Overriden ERC721 logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice         Returns the metadata URI for an NFT.
     *  @dev            See `BatchMintMetadata` for handling of metadata in this contract.
     *
     *  @param _tokenId The tokenId of an NFT.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        string memory fullUriForToken = fullURI[_tokenId];
        if (bytes(fullUriForToken).length > 0) {
            return fullUriForToken;
        }

        string memory batchUri = _getBaseURI(_tokenId);
        return string(abi.encodePacked(batchUri, _tokenId.toString()));
    }

    /*//////////////////////////////////////////////////////////////
                            Minting logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice          Lets an authorized address mint an NFT to a recipient.
     *  @dev             The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.
     *
     *  @param _to       The recipient of the NFT to mint.
     *  @param _tokenURI The full metadata URI for the NFT minted.
     */
    function mintTo(address _to, string memory _tokenURI) public virtual {
        require(_canMint(), "Not authorized to mint.");
        _setTokenURI(nextTokenIdToMint(), _tokenURI);
        _safeMint(_to, 1, "");
    }

    /**
     *  @notice          Lets an authorized address mint multiple NFTs at once to a recipient.
     *  @dev             The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.
     *
     *  @param _to       The recipient of the NFT to mint.
     *  @param _quantity The number of NFTs to mint.
     *  @param _baseURI  The baseURI for the `n` number of NFTs minted. The metadata for each NFT is `baseURI/tokenId`
     *  @param _data     Additional data to pass along during the minting of the NFT.
     */
    function batchMintTo(
        address _to,
        uint256 _quantity,
        string memory _baseURI,
        bytes memory _data
    ) public virtual {
        require(_canMint(), "Not authorized to mint.");
        _batchMintMetadata(nextTokenIdToMint(), _quantity, _baseURI);
        _safeMint(_to, _quantity, _data);
    }

    /**
     *  @notice         Lets an owner or approved operator burn the NFT of the given tokenId.
     *  @dev            ERC721A's `_burn(uint256,bool)` internally checks for token approvals.
     *
     *  @param _tokenId The tokenId of the NFT to burn.
     */
    function burn(uint256 _tokenId) external virtual {
        _burn(_tokenId, true);
    }

    /*//////////////////////////////////////////////////////////////
                        Public getters
    //////////////////////////////////////////////////////////////*/

    /// @notice The tokenId assigned to the next new NFT to be minted.
    function nextTokenIdToMint() public view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @notice Returns whether a given address is the owner, or approved to transfer an NFT.
     *
     * @param _operator The address to check.
     * @param _tokenId  The tokenId of the NFT to check.
     *
     * @return isApprovedOrOwnerOf Whether the given address is approved to transfer the given NFT.
     */
    function isApprovedOrOwner(address _operator, uint256 _tokenId)
        public
        view
        virtual
        returns (bool isApprovedOrOwnerOf)
    {
        address owner = ownerOf(_tokenId);
        isApprovedOrOwnerOf = (_operator == owner ||
            isApprovedForAll(owner, _operator) ||
            getApproved(_tokenId) == _operator);
    }

    /*//////////////////////////////////////////////////////////////
                        Internal (overrideable) functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the metadata URI for a given tokenId.
     *
     * @param _tokenId  The tokenId of the NFT to set the URI for.
     * @param _tokenURI The URI to set for the given tokenId.
     */
    function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal virtual {
        require(bytes(fullURI[_tokenId]).length == 0, "URI already set");
        fullURI[_tokenId] = _tokenURI;
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether a token can be minted in the given execution context.
    function _canMint() internal view virtual returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}

// File: ChromaticEvo.sol


pragma solidity ^0.8.20;




contract ChromaticEvo is ERC721Base{

    mapping(uint256 => string)      private s_tokenIdToUri;
    mapping(uint256 => DynamicData) private tokenData;

    struct  DynamicData {
        address owner;
        uint256 status;
        uint256 mintingTime;
        uint256 durationMs;
    }

        string[] svgData = [
            "'0%' y1='110%' x2='0%' y2='0%'><stop offset='55%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray;black' dur='5000ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='20%' stop-color='red'><animate attributeName='stop-color' values='black; red; green; black' ",
            "'0%' y1='100%' x2='0%' y2='20%'><stop offset='55%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray;black' dur='1700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='120%' stop-color='red'><animate attributeName='stop-color' values='black; red; yellow; green; black' ",
            "'0%' y1='100%' x2='0%' y2='0%'><stop offset='25%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray;black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='35%' stop-color='red'><animate attributeName='stop-color' values='black; red; yellow; brown; green; black' ",
            "'10%' y1='70%' x2='60%' y2='30%'><stop offset='50%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray;black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='15%' stop-color='red'><animate attributeName='stop-color' values='black; red; yellow; brown; green; blue; black' ",
            "'40%' y1='0%' x2='30%' y2='0%'><stop offset='5%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray;black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='180%' stop-color='red'><animate attributeName='stop-color' values='black; red; green; black' ",
            "'10%' y1='10%' x2='50%' y2='0%'><stop offset='5%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray; black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='80%' stop-color='red'><animate attributeName='stop-color' values='black; red; green; black' ",
            "'60%' y1='10%' x2='5%' y2='60%'><stop offset='11%' stop-color='black'><animate attributeName='stop-color' values='red; green; white; blue; gray; black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='110%' stop-color='red'><animate attributeName='stop-color' values='black; red; gray; yellow; navy; green; black' ",
            "'10%' y1='70%' x2='60%' y2='30%'><stop offset='50%' stop-color='black'><animate attributeName='stop-color' values='red; blue; green; blue; gray; black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='105%' stop-color='red'><animate attributeName='stop-color' values='black; red; yellow;  green; blue; black' ",
            "'47%' y1='130%' x2='16%' y2='66%'><stop offset='97%' stop-color='green'><animate attributeName='stop-color' values='red; blue; white; green; blue; gray; black' dur='9700ms' begin='5s' repeatCount='indefinite' /></stop><stop offset='20%' stop-color='black'><animate attributeName='stop-color' values='black; red; yellow;  green; blue; black' ",
            "'147%' y1='130%' x2='116%' y2='19%'><stop offset='97%' stop-color='white'><animate attributeName='stop-color' values='red; blue; white; green; blue; gray; black; white' dur='8700ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='2%' stop-color='black'><animate attributeName='stop-color' values='black; red; yellow;  green; blue; black' ",
            "'10%' y1='56%' x2='30%' y2='0%'><stop offset='55%' stop-color='white'><animate attributeName='stop-color' values='white; yellow; blue; gray; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='120%' stop-color='black'><animate attributeName='stop-color' values='black; red; green; black' ",
            "'10%' y1='30%' x2='60%' y2='30%'><stop offset='5%' stop-color='yellow'><animate attributeName='stop-color' values='red; green; blue; gray; black; blue; yellow' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='72%' stop-color='red'><animate attributeName='stop-color' values='black; red; yellow; brown; green; blue; black' ",
            "'0%' y1='110%' x2='0%' y2='0%'><stop offset='75%' stop-color='red'><animate attributeName='stop-color' values='red; navy; white; green; blue; gray;black' dur='5000ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='120%' stop-color='green'><animate attributeName='stop-color' values='white; black; red; green; black' ",
            "'0%' y1='110%' x2='0%' y2='0%'><stop offset='5%' stop-color='red'><animate attributeName='stop-color' values='red; navy; white; green; blue; gray;black' dur='5000ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='10%' stop-color='green'><animate attributeName='stop-color' values='white; black; red; green; black' ",
            "'0%' y1='14%' x2='10%' y2='10%'><stop offset='55%' stop-color='red'><animate attributeName='stop-color' values='red; navy; white; green; blue; gray;black' dur='5000ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='30%' stop-color='white'><animate attributeName='stop-color' values='white; black; red; green; black' ",
            "'100%' y1='19%' x2='10%' y2='10%'><stop offset='59%' stop-color='red'><animate attributeName='stop-color' values='red;  white; black' dur='5000ms' begin='7s' repeatCount='indefinite' /></stop><stop offset='3%' stop-color='white'><animate attributeName='stop-color' values='white; black; red; green; black' ",
            "'60%' y1='190%' x2='10%' y2='70%'><stop offset='90%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='24%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'0%' y1='100%' x2='0%' y2='20%'><stop offset='55%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray;black' dur='1700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='120%' stop-color='red'><animate attributeName='stop-color' values='black; red; yellow; green; black' ",
            "'0%' y1='100%' x2='0%' y2='0%'><stop offset='25%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray;black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='35%' stop-color='red'><animate attributeName='stop-color' values='black; red; yellow; brown; green; black' ",
            "'10%' y1='70%' x2='60%' y2='30%'><stop offset='50%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray;black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='15%' stop-color='red'><animate attributeName='stop-color' values='black; red; yellow; brown; green; blue; black' ",
            "'40%' y1='0%' x2='30%' y2='0%'><stop offset='5%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray;black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='180%' stop-color='red'><animate attributeName='stop-color' values='black; red; green; black' ",
            "'10%' y1='10%' x2='50%' y2='0%'><stop offset='5%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray; black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='80%' stop-color='red'><animate attributeName='stop-color' values='black; red; green; black' ",
            "'60%' y1='10%' x2='5%' y2='60%'><stop offset='11%' stop-color='black'><animate attributeName='stop-color' values='red; green; white; blue; gray; black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='110%' stop-color='red'><animate attributeName='stop-color' values='black; red; gray; yellow; navy; green; black' ",
            "'10%' y1='70%' x2='60%' y2='30%'><stop offset='50%' stop-color='black'><animate attributeName='stop-color' values='red; blue; green; blue; gray; black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='105%' stop-color='red'><animate attributeName='stop-color' values='black; red; yellow;  green; blue; black' ",
            "'47%' y1='130%' x2='16%' y2='66%'><stop offset='97%' stop-color='green'><animate attributeName='stop-color' values='red; blue; white; green; blue; gray; black' dur='9700ms' begin='5s' repeatCount='indefinite' /></stop><stop offset='20%' stop-color='black'><animate attributeName='stop-color' values='black; red; yellow;  green; blue; black' ",
            "'147%' y1='130%' x2='116%' y2='19%'><stop offset='97%' stop-color='white'><animate attributeName='stop-color' values='red; blue; white; green; blue; gray; black; white' dur='8700ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='2%' stop-color='black'><animate attributeName='stop-color' values='black; red; yellow;  green; blue; black' ",
            "'10%' y1='56%' x2='30%' y2='0%'><stop offset='55%' stop-color='white'><animate attributeName='stop-color' values='white; yellow; blue; gray; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='120%' stop-color='black'><animate attributeName='stop-color' values='black; red; green; black' ",
            "'10%' y1='30%' x2='60%' y2='30%'><stop offset='5%' stop-color='yellow'><animate attributeName='stop-color' values='red; green; blue; gray; black; blue; yellow' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='72%' stop-color='red'><animate attributeName='stop-color' values='black; red; yellow; brown; green; blue; black' ",
            "'0%' y1='110%' x2='0%' y2='0%'><stop offset='75%' stop-color='red'><animate attributeName='stop-color' values='red; navy; white; green; blue; gray;black' dur='5000ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='120%' stop-color='green'><animate attributeName='stop-color' values='white; black; red; green; black' ",
            "'0%' y1='110%' x2='0%' y2='0%'><stop offset='5%' stop-color='red'><animate attributeName='stop-color' values='red; navy; white; green; blue; gray;black' dur='5000ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='10%' stop-color='green'><animate attributeName='stop-color' values='white; black; red; green; black' ",
            "'0%' y1='14%' x2='10%' y2='10%'><stop offset='55%' stop-color='red'><animate attributeName='stop-color' values='red; navy; white; green; blue; gray;black' dur='5000ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='30%' stop-color='white'><animate attributeName='stop-color' values='white; black; red; green; black' ",
            "'100%' y1='19%' x2='10%' y2='10%'><stop offset='59%' stop-color='red'><animate attributeName='stop-color' values='red;  white; black' dur='5000ms' begin='7s' repeatCount='indefinite' /></stop><stop offset='3%' stop-color='white'><animate attributeName='stop-color' values='white; black; red; green; black' ",
            "'60%' y1='190%' x2='10%' y2='70%'><stop offset='90%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='24%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'60%' y1='170%' x2='10%' y2='70%'><stop offset='80%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'60%' y1='70%' x2='10%' y2='0%'><stop offset='70%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'160%' y1='170%' x2='10%' y2='70%'><stop offset='70%' stop-color='black'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'10%' y1='210%' x2='10%' y2='70%'><stop offset='75%' stop-color='#3d0099'><animate attributeName='stop-color' values='#d98079;  #ff80bf;  ##7ad62f;  #3d0099; #66ba72  #00aaff; #5faee3 black' dur='8000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='100%' stop-color='white'><animate attributeName='stop-color' values='white; ##7ad62f;  #3d0099; #66ba72;' ",
            "'23%' y1='0%' x2='52%' y2='0%'><stop offset='110%' stop-color='black'><animate attributeName='stop-color' values='#7b8e9c; #8599d4; #ba2952; #baa429; black' dur='4700ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='150%' stop-color='#ba2952'><animate attributeName='stop-color' values='#7b8e9c; #baa429; #8599d4; #ba2952; ' ",
            "'60%' y1='170%' x2='10%' y2='70%'><stop offset='80%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'60%' y1='70%' x2='10%' y2='0%'><stop offset='70%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'160%' y1='170%' x2='10%' y2='70%'><stop offset='70%' stop-color='black'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'10%' y1='210%' x2='10%' y2='70%'><stop offset='75%' stop-color='#3d0099'><animate attributeName='stop-color' values='#d98079;  #ff80bf;  ##7ad62f;  #3d0099; #66ba72  #00aaff; #5faee3 black' dur='8000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='100%' stop-color='white'><animate attributeName='stop-color' values='white; ##7ad62f;  #3d0099; #66ba72;' ",
            "'60%' y1='170%' x2='10%' y2='70%'><stop offset='80%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'60%' y1='70%' x2='10%' y2='0%'><stop offset='70%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'160%' y1='170%' x2='10%' y2='70%'><stop offset='70%' stop-color='black'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'10%' y1='210%' x2='10%' y2='70%'><stop offset='75%' stop-color='#3d0099'><animate attributeName='stop-color' values='#d98079;  #ff80bf;  ##7ad62f;  #3d0099; #66ba72  #00aaff; #5faee3 black' dur='8000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='100%' stop-color='white'><animate attributeName='stop-color' values='white; ##7ad62f;  #3d0099; #66ba72;' ",
            "'23%' y1='0%' x2='52%' y2='0%'><stop offset='110%' stop-color='black'><animate attributeName='stop-color' values='#7b8e9c; #8599d4; #ba2952; #baa429; black' dur='4700ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='150%' stop-color='#ba2952'><animate attributeName='stop-color' values='#7b8e9c; #baa429; #8599d4; #ba2952; ' ",
            "'60%' y1='170%' x2='10%' y2='70%'><stop offset='80%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'60%' y1='70%' x2='10%' y2='0%'><stop offset='70%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'60%' y1='170%' x2='10%' y2='70%'><stop offset='80%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'60%' y1='70%' x2='10%' y2='0%'><stop offset='70%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'160%' y1='170%' x2='10%' y2='70%'><stop offset='70%' stop-color='black'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'10%' y1='210%' x2='10%' y2='70%'><stop offset='75%' stop-color='#3d0099'><animate attributeName='stop-color' values='#d98079;  #ff80bf;  ##7ad62f;  #3d0099; #66ba72  #00aaff; #5faee3 black' dur='8000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='100%' stop-color='white'><animate attributeName='stop-color' values='white; ##7ad62f;  #3d0099; #66ba72;' ",
            "'23%' y1='0%' x2='52%' y2='0%'><stop offset='110%' stop-color='black'><animate attributeName='stop-color' values='#7b8e9c; #8599d4; #ba2952; #baa429; black' dur='4700ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='150%' stop-color='#ba2952'><animate attributeName='stop-color' values='#7b8e9c; #baa429; #8599d4; #ba2952; ' ",
            "'160%' y1='170%' x2='10%' y2='70%'><stop offset='70%' stop-color='black'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'60%' y1='70%' x2='10%' y2='0%'><stop offset='70%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'160%' y1='170%' x2='10%' y2='70%'><stop offset='70%' stop-color='black'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'60%' y1='70%' x2='10%' y2='0%'><stop offset='70%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'160%' y1='170%' x2='10%' y2='70%'><stop offset='70%' stop-color='black'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'10%' y1='210%' x2='10%' y2='70%'><stop offset='75%' stop-color='#3d0099'><animate attributeName='stop-color' values='#d98079;  #ff80bf;  ##7ad62f;  #3d0099; #66ba72  #00aaff; #5faee3 black' dur='8000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='100%' stop-color='white'><animate attributeName='stop-color' values='white; ##7ad62f;  #3d0099; #66ba72;' ",
            "'160%' y1='170%' x2='10%' y2='70%'><stop offset='70%' stop-color='black'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'10%' y1='210%' x2='10%' y2='70%'><stop offset='75%' stop-color='#3d0099'><animate attributeName='stop-color' values='#d98079;  #ff80bf;  ##7ad62f;  #3d0099; #66ba72  #00aaff; #5faee3 black' dur='8000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='100%' stop-color='white'><animate attributeName='stop-color' values='white; ##7ad62f;  #3d0099; #66ba72;' ",
            "'10%' y1='210%' x2='10%' y2='70%'><stop offset='75%' stop-color='#3d0099'><animate attributeName='stop-color' values='#d98079;  #ff80bf;  ##7ad62f;  #3d0099; #66ba72  #00aaff; #5faee3 black' dur='8000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='100%' stop-color='white'><animate attributeName='stop-color' values='white; ##7ad62f;  #3d0099; #66ba72;' ",
            "'23%' y1='0%' x2='52%' y2='0%'><stop offset='110%' stop-color='black'><animate attributeName='stop-color' values='#7b8e9c; #8599d4; #ba2952; #baa429; black' dur='4700ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='150%' stop-color='#ba2952'><animate attributeName='stop-color' values='#7b8e9c; #baa429; #8599d4; #ba2952; ' ",
            "'60%' y1='170%' x2='10%' y2='70%'><stop offset='80%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'60%' y1='70%' x2='10%' y2='0%'><stop offset='70%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'160%' y1='170%' x2='10%' y2='70%'><stop offset='70%' stop-color='black'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'10%' y1='210%' x2='10%' y2='70%'><stop offset='75%' stop-color='#3d0099'><animate attributeName='stop-color' values='#d98079;  #ff80bf;  ##7ad62f;  #3d0099; #66ba72  #00aaff; #5faee3 black' dur='8000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='100%' stop-color='white'><animate attributeName='stop-color' values='white; ##7ad62f;  #3d0099; #66ba72;' ",
            "'160%' y1='170%' x2='10%' y2='70%'><stop offset='70%' stop-color='black'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'10%' y1='210%' x2='10%' y2='70%'><stop offset='75%' stop-color='#3d0099'><animate attributeName='stop-color' values='#d98079;  #ff80bf;  ##7ad62f;  #3d0099; #66ba72  #00aaff; #5faee3 black' dur='8000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='100%' stop-color='white'><animate attributeName='stop-color' values='white; ##7ad62f;  #3d0099; #66ba72;' ",
            "'23%' y1='0%' x2='52%' y2='0%'><stop offset='110%' stop-color='black'><animate attributeName='stop-color' values='#7b8e9c; #8599d4; #ba2952; #baa429; black' dur='4700ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='150%' stop-color='#ba2952'><animate attributeName='stop-color' values='#7b8e9c; #baa429; #8599d4; #ba2952; ' ",
            "'123%' y1='150%' x2='10%' y2='120%'><stop offset='10%' stop-color='black'><animate attributeName='stop-color' values='#7b8e9c; #8599d4; #ba2952; #baa429; black' dur='4700ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='130%' stop-color='#7b8e9c'><animate attributeName='stop-color' values='yellow; #7b8e9c; #baa429; #8599d4; #ba2952; ' "
        ];


    event Minted(uint256 tokenId, address owner);
    

    constructor(
        string memory _name,
        string memory _symbol
        
    ) ERC721Base( msg.sender, _name, _symbol
      , msg.sender, 0
    ) {
    }


    
    function mintTo(address _to, string memory _tokenURI) public override {
        require(_canMint(), "Not authorized to mint.");

        uint256 nextTokenId = nextTokenIdToMint();
        

        DynamicData memory dynamicData = DynamicData({
            owner: msg.sender,
            status: 0,
            mintingTime: block.timestamp,
            durationMs: 7000
        });


        tokenData[nextTokenId] = dynamicData;
        s_tokenIdToUri[nextTokenId] = tokenURI(nextTokenId);

        _setTokenURI(nextTokenId, s_tokenIdToUri[nextTokenId]);

        _safeMint(_to, 1, "");
    }



    function tokenURI(uint256 _id) public view override returns (string memory) {
       DynamicData storage dynamicData = tokenData[_id];    
       string memory durationMs = u2str(dynamicData.durationMs); 
    
       string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": "#',u2str(_id),'",',
                    '"image": "data:image/svg+xml;base64,',Base64.encode(bytes(makeSVG(_id))),'",',
                    '"attributes": [{"trait_type": "duration_ms", "value": "',durationMs,'" }',
                    ']}'
                )
            ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
 
    }

    function makeSVG(uint256 id) public view returns (string memory ) {

        string memory _svgData = svgData[id];        

        DynamicData storage dynamicData = tokenData[id];    
        string memory durationMs = u2str(dynamicData.durationMs);

         string memory res  = string(abi.encodePacked("<svg width='350px' height='350px' xmlns='http://www.w3.org/2000/svg'>",
                  "<linearGradient id='gradient'  x1=",
                  _svgData,
                  "dur='",durationMs,"ms' begin='0s' repeatCount='indefinite' /></stop></linearGradient><rect x='80' y='80' id='shape' width='200' height='200' fill='url(#gradient)'/></svg>"));
        return res;
    }

    
    /*
     * Dynamic function that provides an evolving dimension to the NFT.
     * The owner can change this duration parameter to alter the
     * shadow play of the NFT.
     */
    function dfChangeDuration(uint256 _tokenId, uint256 _durationMs)  public   {
        
        DynamicData storage dynamicData = tokenData[_tokenId];
        require(msg.sender == dynamicData.owner, "Only the owner can change the duration");

        dynamicData.durationMs = _durationMs;       

    }

    function getTokenData(uint256 tokenId) public view returns (address, uint256, uint256, uint256) {
        DynamicData memory dd = tokenData[tokenId];
        return (dd.owner, dd.status, dd.mintingTime, dd.durationMs);
    }

    function splitHash(string memory str) public pure returns(string[10] memory) {
        
        string[10]  memory res;       
        string      memory hash = TWStrings.toHexString(uint256(keccak256(abi.encodePacked(str))), 32);           
        bytes       memory a = bytes(hash);
        uint        s = 2;       

        for(uint i=0; i < 10; i++){                           
          res[i] = string(abi.encodePacked(a[s],a[s+1],a[s+2],a[s+3],a[s+4],a[s+5]));
          s  = s + 6;         
        } 

        return res;        
    }  

    function toUint256(string memory str) public pure returns (uint256 value) {

        bytes memory _bytes= bytes(str);
        assembly {value := mload(add(_bytes, 0x20))}
        return value/10**70;
    }

    function u2str(uint _i) internal pure returns (string memory _str) {
      if (_i == 0) { return "0";}
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      while (_i != 0) {
          k = k-1;
          uint8 temp = (48 + uint8(_i - _i / 10 * 10));
          bytes1 b1 = bytes1(temp);
          bstr[k] = b1;
          _i /= 10;
      }
      return string(bstr);
  }
}