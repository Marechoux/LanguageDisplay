<?php

class BlizzardAPI {
    const API_OAUTH_TOKEN_URL = 'https://oauth.battle.net/oauth/token';

    private string $_client_id;
    private string $_client_secret;

    private string $_base_url;
    private string $_namespace;
    private string $_locale;

    private string $_bearer;

    public function __construct($client_id, $client_secret, $region) {
        $this->_client_id = $client_id;
        $this->_client_secret = $client_secret;

        $this->_base_url = $region['base_url'];
        $this->_namespace = $region['namespace'];
        $this->_locale = $region['locale'];
    }

    private function getBearer() {
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, self::API_OAUTH_TOKEN_URL);
        curl_setopt($ch, CURLOPT_POST, 1);
        curl_setopt($ch, CURLOPT_POSTFIELDS, "grant_type=client_credentials");
        curl_setopt($ch, CURLOPT_USERPWD, "{$this->_client_id}:{$this->_client_secret}");
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        $result = curl_exec($ch);

        if (curl_errno($ch)) {
            echo 'Erreur : ' . curl_error($ch);
            curl_close($ch);
            return false;
        } 

        $result = json_decode($result, true);
        $this->_bearer = $result['access_token'];
        curl_close($ch);

        return true;
    }

    private function callApi($endpoint) {
        if(empty($this->_bearer))
            $this->getBearer();

        $url = "{$this->_base_url}{$endpoint}?namespace={$this->_namespace}&locale={$this->_locale}&access_token={$this->_bearer}";

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        $response = curl_exec($ch);
        if (curl_errno($ch)) {
            echo 'Erreur : ' . curl_error($ch);
        } 
        curl_close($ch);

        return $response;
    }

    public function listRealms() {
        return $this->callApi("/data/wow/realm/index");
    }

    public function getRealm($slug) {
        return $this->callApi("/data/wow/realm/$slug");
    }
}

class Utils {
    const REGIONS = [
        1 => [
            'name' => 'us',
            'base_url' => 'https://us.api.blizzard.com',
            'namespace' => 'dynamic-us',
            'locale' => 'en_US'
        ],
        2 => [
            'name' => 'korea',
            'fixedValue' => 'ko_KR'
        ],
        3 => [
            'name' => 'europe',
            'base_url' => 'https://eu.api.blizzard.com',
            'namespace' => 'dynamic-eu',
            'locale' => 'en_GB'
        ],
        4 => [
            'name' => 'taiwan',
            'fixedValue' => 'zh_TW'
        ],
        5 => [
            'name' => 'china',
            'fixedValue' => 'zh_CN'
        ]
    ];

    /**
     * Converts a realm name to the in-game one
     * @param string $realmName
     * @return string
     */
    public static function convertRealmName($realmName): string {
        $inGameName = mb_strtolower($realmName);
        $inGameName = str_replace(" ", "", $inGameName);
    
        $inGameName = str_replace(
            ['á', 'à', 'â', 'ä', 'ã', 'å', 'æ', 'ç', 'é', 'è', 'ê', 'ë', 'í', 'ì', 'î', 'ï', 'ñ', 'ó', 'ò', 'ô', 'ö', 'õ', 'ø', 'œ', 'ú', 'ù', 'û', 'ü', 'ý', 'ÿ', 'ß'],
            ['a', 'a', 'a', 'a', 'a', 'a', 'ae', 'c', 'e', 'e', 'e', 'e', 'i', 'i', 'i', 'i', 'n', 'o', 'o', 'o', 'o', 'o', 'o', 'oe', 'u', 'u', 'u', 'u', 'y', 'y', 'ss'],
            $inGameName
        );
    
        $inGameName = preg_replace("/[^a-z0-9]/", "", $inGameName);
    
        return $inGameName;
    }

    /**
     * Saves the data as LUA
     * @param array $languages
     * @param string $filename
     * @return int|false
     */
    public static function saveAsLUA($regions, $filename): int|false {
        $lua = 'LDRealms = LDRealms or {}' . PHP_EOL . PHP_EOL;

        foreach ($regions as $region_id => $data) {
            if($data === false) {
                $lua .= 'LDRealms['.$region_id.'] = "'. Utils::REGIONS[$region_id]['fixedValue'] .'"' . PHP_EOL . PHP_EOL;
                continue;
            }

            $last_key = array_key_last($data);
            $lua .= 'LDRealms['.$region_id.'] = {' . PHP_EOL;

            foreach ($data as $realm_id => $realm) {
                if ($realm !== $last_key) 
                    $lua .= '    ['. $realm_id .'] = "'. $realm['locale'] . '", -- ' . $realm['name'] . PHP_EOL;
                else
                    $lua .= '    ['. $realm_id .'] = "'. $realm['locale'] . '"' . $realm['name'] . PHP_EOL;
            }

            $lua .= '}' . PHP_EOL . PHP_EOL;
        }

        return file_put_contents($filename, $lua);
    }
}

if ($_SERVER['argc'] != 3) {
    echo "Syntax error: ".$argv[0] ."\n";
    exit (1);
}

$client_id = $argv[1];
$client_secret = $argv[2];

$languages = [];

foreach (Utils::REGIONS as $region_id => $region) {
    $start_time = microtime(true);

    if (!empty($region['fixedValue'])) {
        $languages[$region_id] = false;
        continue;
    }

    $api = new BlizzardAPI($client_id, $client_secret, $region);
    $realms = json_decode($api->listRealms(), true);

    foreach($realms['realms'] as $realm) {
        $realm_data = json_decode($api->getRealm($realm['slug']), true);

        if (empty($languages[$region_id])) {
            $languages[$region_id] = [];
        }

        $languages[$region_id][$realm['id']] = [
            'name' => $realm['name'],
            'locale' => $realm_data['locale']
        ];
    }
    
    $end_time = microtime(true);
    $execution_time = round($end_time - $start_time, 4);
    echo "Region $region_id took $execution_time s \n";
}

Utils::saveAsLUA($languages, 'database.lua');