/**
    (                                                                        
    )\ )                   )        (                                        
    (()/(      )         ( /(   (    )\ )  (             )                (   
    /(_))  ( /(   (     )\()) ))\  (()/(  )\   (     ( /(   (      (    ))\  
    (_))_   )(_))  )\ ) (_))/ /((_)  /(_))((_)  )\ )  )(_))  )\ )   )\  /((_) 
    |   \ ((_)_  _(_/( | |_ (_))   (_) _| (_) _(_/( ((_)_  _(_/(  ((_)(_))   
    | |) |/ _` || ' \))|  _|/ -_)   |  _| | || ' \))/ _` || ' \))/ _| / -_)  
    |___/ \__,_||_||_|  \__|\___|   |_|   |_||_||_| \__,_||_||_| \__| \___|  

 */

const { ethers } = require("hardhat");

async function main() {
    
    //https://rinkeby.etherscan.io/address/0xC07a85d1EE157906954A32B48e63E3734B224709#readContract
    
    // WALLETS
    const __dao = "0x698d286d660B298511E49dA24799d16C74b5640D";
    const __uri = "ipfs://bafybeidzu64jcb67r4kc675flh6rsyz4ck2z6sdkwnhzu2jp4kbnymjpxq/metadata/";

    console.log("deploying nft..");
    const DanteNFT = await ethers.getContractFactory("DanteNFT");

    const nft = await DanteNFT.deploy(    
        __dao,
        "abc"
    );

    console.log("nft address: ", nft.address);
}
    
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });