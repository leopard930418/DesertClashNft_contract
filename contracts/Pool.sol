// // SPDX-License-Identifier: MIT LICENSE

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";

// import "./Camelit.sol";
// import "./GOLD.sol";

// contract Pool is Ownable, IERC721Receiver, Pausable {
  
//   // maximum alpha score for a Wolf
//   uint8 public constant MAX_ALPHA = 8;

//   // struct to store a stake's token, owner, and earning values
//   struct Stake {
//     uint16 tokenId;
//     uint80 value;
//     address owner;
//   }

//   event TokenStaked(address owner, uint256 tokenId, uint256 value);
//   event CamelClaimed(uint256 tokenId, uint256 earned, bool unstaked);
//   event BanditClaimed(uint256 tokenId, uint256 earned, bool unstaked);

//   // reference to the Camelit NFT contract
//   Camelit camelit;
//   // reference to the $GOLD contract for minting $GOLD earnings
//   GOLD gold;

//   // maps tokenId to stake
//   mapping(uint256 => Stake) public pool; 
// //   // maps alpha to all Bandit stakes with that alpha
// //   mapping(uint256 => Stake[]) public pack; 
// //   // tracks location of each Bandit in Pack
// //   mapping(uint256 => uint256) public packIndices; 
// //   // total alpha scores staked
// //   uint256 public totalAlphaStaked = 0; 
//   // any rewards distributed when no bandits are staked
//   uint256 public unaccountedRewards = 0; 
//   // amount of $GOLD due for each alpha point staked
//   uint256 public goldPerBandit = 0; 

//   // camel earn 20 $GOLD per day
//   uint256 public constant DAILY_GOLD_RATE = 20 ether;
// //   // sheep must have 2 days worth of $WOOL to unstake or else it's too cold
// //   uint256 public constant MINIMUM_TO_EXIT = 2 days;
//   // bandits take a 15% tax on all $GOLD claimed
//   uint256 public constant GOLD_CLAIM_TAX_PERCENTAGE = 15;
//   // there will only ever be (roughly) 2.4 billion $WOOL earned through staking
//   uint256 public constant MAXIMUM_GLOBAL_GOLD = 7500000 ether;

//   // amount of $GOLD earned so far
//   uint256 public totalGoldEarned;
//   // number of Camel staked in the Pool
//   uint256 public totalCamelStaked;
//   // number of Bandit staked in the Pool
//   uint256 public totalBanditStaked;
//   // the last time $GOLD was claimed
//   uint256 public lastClaimTimestamp;

//   // emergency rescue to allow unstaking without any checks but without $GOLD
//   bool public rescueEnabled = false;

//   /**
//    * @param _camelit reference to the Camelit NFT contract
//    * @param _gold reference to the $GOLD token
//    */
//   constructor(address _camelit, address _gold) { 
//     camelit = Camelit(_camelit);
//     gold = GOLD(_gold);
//   }

//   /** STAKING */

//   /**
//    * adds Camels and Bandits to the Pool and Pack
//    * @param account the address of the staker
//    * @param tokenIds the IDs of the Camels and Bandits to stake
//    */
//   function addManyToPoolAndPack(address account, uint16[] calldata tokenIds) external {
//     require(account == _msgSender() || _msgSender() == address(camelit), "DONT GIVE YOUR TOKENS AWAY");
//     for (uint i = 0; i < tokenIds.length; i++) {
//       if (_msgSender() != address(camelit)) { // dont do this step if its a mint + stake
//         require(camelit.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
//         camelit.transferFrom(_msgSender(), address(this), tokenIds[i]);
//       } else if (tokenIds[i] == 0) {
//         continue; // there may be gaps in the array for stolen tokens
//       }

//       if (isCamel(tokenIds[i])) 
//         _addCamelitToPool(account, tokenIds[i], true);
//       else 
//         _addCamelitToPool(account, tokenIds[i], false);
//     }
//   }

//   /**
//    * adds a single Camelit to the Pool
//    * @param account the address of the staker
//    * @param tokenId the ID of the Camelit to add to the Pool
//    */
//   function _addCamelitToPool(address account, uint256 tokenId, bool carmel) internal whenNotPaused _updateEarnings {
//     if (carmel) {
//         pool[tokenId] = Stake({
//         owner: account,
//         tokenId: uint16(tokenId),
//         value: uint80(block.timestamp)
//         });
//         totalCamelStaked += 1;
//     }
//     else {
//         pool[tokenId] = Stake({
//         owner: account,
//         tokenId: uint16(tokenId),
//         value: uint80(goldPerBandit)
//         });
//         totalBanditStaked += 1;
//     }
//     emit TokenStaked(account, tokenId, block.timestamp);
//   }

//   /** CLAIMING / UNSTAKING */

//   /**
//    * realize $GOLD earnings and optionally unstake tokens from the Pool
//    * @param tokenIds the IDs of the tokens to claim earnings from
//    * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
//    */
//   function claimManyFromPool(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings {
//     uint256 owed = 0;
//     for (uint i = 0; i < tokenIds.length; i++) {
//       if (isCamel(tokenIds[i]))
//         owed += _claimCamelFromPool(tokenIds[i], unstake);
//       else
//         owed += _claimBanditFromPool(tokenIds[i], unstake);
//     }
//     if (owed == 0) return;
//     gold.mint(_msgSender(), owed);
//   }

//   /**
//    * realize $GOLD earnings for a single Camel and optionally unstake it
//    * pay a 15% tax to the staked Wolves
//    * @param tokenId the ID of the Camel to claim earnings from
//    * @param unstake whether or not to unstake the Camel
//    * @return owed - the amount of $GOLD earned
//    */
//   function _claimCamelFromPool(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
//     Stake memory stake = pool[tokenId];
//     require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
//     require(!(unstake), "UNSTAKING TOKEN");
//     if (totalGoldEarned < MAXIMUM_GLOBAL_GOLD) {
//       owed = (block.timestamp - stake.value) * DAILY_GOLD_RATE / 1 days;
//     } else if (stake.value > lastClaimTimestamp) {
//       owed = 0; // $WOOL production stopped already
//     } else {
//       owed = (lastClaimTimestamp - stake.value) * DAILY_GOLD_RATE / 1 days; // stop earning additional $GOLD if it's all been earned
//     }
//     _payBanditTax(owed * GOLD_CLAIM_TAX_PERCENTAGE / 100); // percentage tax to staked bandits
//     owed = owed * (100 - GOLD_CLAIM_TAX_PERCENTAGE) / 100; // remainder goes to Camel owner

//     if (unstake) {
//       camelit.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Camel
//       delete pool[tokenId];
//       totalCamelStaked -= 1;
//     } else {
//       pool[tokenId] = Stake({
//         owner: _msgSender(),
//         tokenId: uint16(tokenId),
//         value: uint80(block.timestamp)
//       }); // reset stake
//     }
//     emit CamelClaimed(tokenId, owed, unstake);
//   }

//   /**
//    * realize $GOLD earnings for a single Bandit and optionally unstake it
//    * Bandits earn $GOLD
//    * @param tokenId the ID of the Bandit to claim earnings from
//    * @param unstake whether or not to unstake the Bandit
//    * @return owed - the amount of $GOLD earned
//    */
//   function _claimBanditFromPool(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
//     require(camelit.ownerOf(tokenId) == address(this), "AINT A PART OF THE POOL");
//     Stake memory stake = pool[tokenId];
//     require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
//     owed = goldPerBandit - stake.value; // Calculate portion of tokens based
//     if (unstake) {
//       camelit.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Wolf
//       delete pool[tokenId];
//     } else {
//       pool[tokenId] = Stake({
//         owner: _msgSender(),
//         tokenId: uint16(tokenId),
//         value: uint80(goldPerBandit)
//       }); // reset stake
//     }
//     emit BanditClaimed(tokenId, owed, unstake);
//   }

//   /**
//    * emergency unstake tokens
//    * @param tokenIds the IDs of the tokens to claim earnings from
//    */
//   function rescue(uint256[] calldata tokenIds) external {
//     require(rescueEnabled, "RESCUE DISABLED");
//     uint256 tokenId;
//     Stake memory stake;
//     for (uint i = 0; i < tokenIds.length; i++) {
//         tokenId = tokenIds[i];
//         stake = pool[tokenId];

//         require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
//         camelit.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Camel
//         delete pool[tokenId];

//       if (isCamel(tokenId)) {
//         totalCamelStaked -= 1;
//         emit CamelClaimed(tokenId, 0, true);
//       } else {
//         totalBanditStaked -= 1;
//         emit BanditClaimed(tokenId, 0, true);
//       }
//     }
//   }

//   /** ACCOUNTING */

//   /** 
//    * add $GOLD to claimable pot for the Pool
//    * @param amount $GOLD to add to the pot
//    */
//   function _payBanditTax(uint256 amount) internal {
//     if (totalBanditStaked == 0) { // if there's no staked wolves
//       unaccountedRewards += amount; // keep track of $GOLD due to wolves
//       return;
//     }
//     // makes sure to include any unaccounted $GOLD
//     goldPerBandit += (amount + unaccountedRewards) / totalBanditStaked;
//     unaccountedRewards = 0;
//   }

//   /**
//    * tracks $GOLD earnings to ensure it stops once 7.5 million is eclipsed
//    */
//   modifier _updateEarnings() {
//     if (totalGoldEarned < MAXIMUM_GLOBAL_GOLD) {
//       totalGoldEarned += 
//         (block.timestamp - lastClaimTimestamp)
//         * totalCamelStaked
//         * DAILY_GOLD_RATE / 1 days; 
//       lastClaimTimestamp = block.timestamp;
//     }
//     _;
//   }

//   /** ADMIN */

//   /**
//    * allows owner to enable "rescue mode"
//    * simplifies accounting, prioritizes tokens out in emergency
//    */
//   function setRescueEnabled(bool _enabled) external onlyOwner {
//     rescueEnabled = _enabled;
//   }

//   /**
//    * enables owner to pause / unpause minting
//    */
//   function setPaused(bool _paused) external onlyOwner {
//     if (_paused) _pause();
//     else _unpause();
//   }

//   /** READ ONLY */

//   /**
//    * checks if a token is a Camel
//    * @param tokenId the ID of the token to check
//    * @return camel - whether or not a token is a Camel
//    */
//   function isCamel(uint256 tokenId) public view returns (bool camel) {
//     (camel, , , , , , , , , ,) = camelit.tokenTraits(tokenId);
//   }

// //   /**
// //    * gets the alpha score for a Wolf
// //    * @param tokenId the ID of the Wolf to get the alpha score for
// //    * @return the alpha score of the Wolf (5-8)
// //    */
// //   function _alphaForWolf(uint256 tokenId) internal view returns (uint8) {
// //     ( , , , , , , , , , uint8 alphaIndex) = woolf.tokenTraits(tokenId);
// //     return MAX_ALPHA - alphaIndex; // alpha index is 0-3
// //   }

//   /**
//    * chooses a random Bandit when a newly minted token is stolen
//    * @param seed a random value to choose a Bandit from
//    * @return the owner of the randomly selected Bandit
//    */
//   function randomBanditOwner(uint256 seed) external view returns (address) {
//     if (totalBanditStaked == 0) return address(0x0);
//     uint256 bucket = (seed & 0xFFFFFFFF) % totalBanditStaked; // choose a value from 0 to total bandit staked
//     seed >>= 32;
//     if (bucket < totalBanditStaked)
//       return pool[seed % totalBanditStaked].owner;
//     return address(0x0);
//   }

//   /**
//    * generates a pseudorandom number
//    * @param seed a value ensure different outcomes for different sources in the same block
//    * @return a pseudorandom value
//    */
//   function random(uint256 seed) internal view returns (uint256) {
//     return uint256(keccak256(abi.encodePacked(
//       tx.origin,
//       blockhash(block.number - 1),
//       block.timestamp,
//       seed
//     )));
//   }

//   function onERC721Received(
//         address,
//         address from,
//         uint256,
//         bytes calldata
//     ) external pure override returns (bytes4) {
//       require(from == address(0x0), "Cannot send tokens to Pool directly");
//       return IERC721Receiver.onERC721Received.selector;
//     }

  
// }