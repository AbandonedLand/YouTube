# Make sure you have the latest PowerChia and PowerDexie Modules
# Import-Module -Name PowerChia
# Import-Module -Name PowerDexie

# Set the NFT_ID to sell
$nft = "nft12jmkfhrj2l722q4wrn5l5lgwvg6u6sjwuh8s6zjmc0ph6yjhektszz3dg8"

$blocks_to_wait = 15

$starting_price = 5


function Wait-ForBlock($height){

    $bc_height = Get-ChiaHeightInfo

    while($bc_height.height -lt $height){
            start-sleep 15
            $bc_height = Get-ChiaHeightInfo
    }
}


function Test-Nft($nft_id){
    $nfts = Invoke-ChiaRPC -section wallet -endpoint nft_get_nfts -json @{}
    $check = $nfts.nft_list | Where-Object { $_.nft_id -eq $nft_id }
    if($check){
            return $true
    } else {
            return $false
    }

}




$starting_price_mojo = $starting_price | ConvertTo-XCHMojo

$price_drop = 0.25 | ConvertTo-XCHMojo

$current_price = $starting_price_mojo

Write-Host "Current Price: $current_price"

while($current_price -gt 0){

        if(-not (Test-Nft -nft_id $nft)){
                Write-Host "NFT Sold"
                break;
        }
        $offer = Build-ChiaOffer
        $offer.offerNft($nft)
        $offer.requestXch($current_price)
        $offer.addBlocksUntilExpiration($blocks_to_wait)
        $offer.validateonly()
        $offer.createoffer()

        Submit-DexieOffer -offer ($offer.showoffer().offer)
        Write-Host "Waiting for block $($offer.max_height)"
        Wait-ForBlock($offer.max_height)

        $current_price = $current_price - $price_drop
}