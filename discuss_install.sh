###############

echo "Installing Dependencies"
apt-get install -y curl
apt-get install -y sudo
apt-get install -y mc
echo "Installed Dependencies"

wget --no-check-certificate https://nodejs.org/dist/v18.20.5/node-v18.20.5-linux-x64.tar.gz -O /tmp/node.tar.gz
tar xzvf /tmp/node.tar.gz --exclude CHANGELOG.md --exclude LICENSE --exclude README.md  -C /usr/local --strip-components=1
rm -rf /tmp/node.tar.gz

npm install -g wrangler@3

mkdir -p /app/discuss
wget --no-check-certificate https://github.com/minlearn/discuss/archive/refs/heads/master.tar.gz -O /tmp/discuss.tar.gz
tar -xzvf /tmp/discuss.tar.gz -C /app/discuss discuss-master/_build --strip-components=2
rm -rf /tmp/discuss.tar.gz
   
cat > /app/discuss/wrangler.toml << 'EOL'
compatibility_date = "2024-03-07"
[[d1_databases]]
binding = "discussdb"
database_name = "discuss_discussdb_development"
database_id = "11111111-1111-1111-1111-111111111111"
[site]
bucket = "./"
EOL

cat > /lib/systemd/system/discussd1.service << 'EOL'
[Unit]
Description=Run once
After=local-fs.target
After=network.target

[Service]
WorkingDirectory=/app/discuss
Type=oneshot
ExecStart=wrangler d1 execute discuss_discussdb_development --file=db.sql --local
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOL

cat > /lib/systemd/system/discuss.service << 'EOL'
[Unit]
Description=this is wrangler service
After=network.target nss-lookup.target
After=discussd1
Wants=network.target nss-lookup.target
Requires=network.target nss-lookup.target

[Service]
WorkingDirectory=/app/discuss
Type=simple
ExecStartPre=/usr/bin/sleep 2
ExecStart=wrangler pages dev ./ --local --ip 0.0.0.0 --port 80
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

systemctl enable discussd1 discuss
systemctl start discussd1 discuss

echo "Cleaning up"
apt-get -y autoremove
apt-get -y autoclean
echo "Cleaned"

##############