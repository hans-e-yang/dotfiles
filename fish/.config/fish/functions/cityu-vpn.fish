function cityu-vpn --description 'Connect to CityU GlobalProtect VPN (SAML/Okta + HIP report)'
    ~/.venvs/gp-saml/bin/gp-saml-gui -P --gateway --clientos=Windows ivpn.cityu.edu.hk \
        --allow-insecure-crypto -- --csd-wrapper=/usr/libexec/openconnect/hipreport.sh $argv
end
