import "@openzeppelin/contracts/access/Ownable.sol";

contract BUIOriginRegistry is Ownable {
    mapping(bytes32 => address) private _ownerOfOrigin;
    mapping(address => bytes32[]) private _originsForAddress;
    mapping(bytes32 => uint256) private _balanceForOrigin;
    mapping(bytes32 => string) private _domainForOrigin;

    uint256 private _minBalance = 0.1 ether;

    event OriginRegistered(address owner, bytes32 origin);
    event OriginUnregistered(address owner, bytes32 origin);

    constructor(uint256 minBalance) {
        _minBalance = minBalance;
    }

    function withdraw() external onlyOwner() {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function register(string memory fqdn) external payable {
        bytes32 origin = keccak256(abi.encodePacked(fqdn));

        require(msg.value >= _minBalance, "Must meet the minimum balance requirement");
        require(_ownerOfOrigin[origin] == address(0), "This origin is already registered");

        bytes32[] storage origins = _originsForAddress[msg.sender];
        for (uint i = 0; i < origins.length; i++) {
            if (origin == origins[i]) {
                revert("Origin already exists");
            }
        }

        _ownerOfOrigin[origin] = msg.sender;
        _originsForAddress[msg.sender].push(origin);
        _balanceForOrigin[origin] += msg.value;
        _domainForOrigin[origin] = fqdn;

        emit OriginRegistered(msg.sender, origin);
    }

    function unregister(bytes32 origin) external {
        require(_ownerOfOrigin[origin] == msg.sender, "Not authorized");

        bytes32[] storage origins = _originsForAddress[msg.sender];

        for (uint i = 0; i < origins.length; i++) {
            if (origin == origins[i]) {
                // Overwrite and shift remaining origins
                for (uint j = i; j < origins.length-1; j++) {
                    origins[j] = origins[j+1];
                }
                origins.pop();

                _originsForAddress[msg.sender] = origins;
                _domainForOrigin[origin] = "";

                uint256 balance = _balanceForOrigin[origin];
                _balanceForOrigin[origin] = 0;

                address payable owner = payable(_ownerOfOrigin[origin]);
                _ownerOfOrigin[origin] = address(0);

                if (balance > 0) {
                    owner.transfer(balance);
                }

                emit OriginUnregistered(msg.sender, origin);

                break;
            }
        }
    }

    function verifyOwner(bytes32 origin, address owner) public view returns (bool) {
        return _ownerOfOrigin[origin] == owner;
    }

    function originsForSender() public view returns (string[] memory) {
        string[] memory origins = new string[](_originsForAddress[msg.sender].length);

        for (uint i = 0; i < _originsForAddress[msg.sender].length; i++) {
            bytes32 origin = _originsForAddress[msg.sender][i];
            origins[i] = _domainForOrigin[origin];
        }

        return origins;
    }

    // TODO: node payout methods
}
