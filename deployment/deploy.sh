# This is the encryption salt
# IT MUST BE UNIQUE BY APPLICATION AND NEVER CHANGED DURING THE LIFETIME OF THE DATABASE
jwtSecret=8twBbf0B_Kj75ow3jY7o3Qm

# Load actual server config variables
. configFiles/deployConfig.cfg || ERROR_CONF_SPE=true
if [ "$ERROR_CONF_SPE" = true ]; then
  echo ""
  echo "--> Ce script ne doit pas être lancé manuellement !"
  exit 1
fi

# Only when updating application
if [ "$installed" = true ]; then
  # Drop old DB application User
  echo ""
  echo "Suppression de l'utilisateur de l'application des utilisateurs de la base de données"
  mysql -u root -proot $dbName -e "DROP USER '$applicationUsername'@'172.17.0.%';";
#  echo "db.dropUser(\"$applicationUsername\")" | mongosh -u sadmin -p sadmin admin TODO: MySQL

  # Try to find a Docker image by name (server config)
  echo ""
  echo "Vérification de l'absence de l'image de l'application sur le serveur ('$dockerImageName')"
  docker image inspect $dockerImageName || ERROR_ABS_IMG=true
  # If an error is thrown -> No image existe -> OK -> Else -> Image already exists -> ABORT
  if [ "$ERROR_ABS_IMG" != true ]; then
    echo ""
    echo "### Une image Docker '$dockerImageName' est déjà déployée sur le serveur ###"
    exit 1
  fi
fi

# Load new config variables
. "$gitRepo"/deployment/deployConfig.cfg # Override the previous deployConfig.cfg imported

# Try to find a Docker image by the name configured in deployConfig.cfg of application
echo ""
echo "Vérification de la disponibilité du nom de l'image ('$dockerImageName')"
docker image inspect $dockerImageName || ERROR_DISP_IMG=true
# If an error is thrown -> No image existe -> OK -> Else -> Image already exists -> ABORT
if [ "$ERROR_DISP_IMG" != true ]; then
  echo ""
  echo "### Une image Docker '$dockerImageName' est déjà déployée sur le serveur ###"
  exit 1
fi

# Load actual server config variables
. configFiles/deployConfig.cfg # Override the previous deployConfig.cfg imported

# Specify the port used by the container (80 for Angular)
echo "" >>configFiles/deployConfig.cfg
echo "### For start.sh script ###" >>"$gitRepo"/deployment/deployConfig.cfg
echo "containerPort=8000" >>"$gitRepo"/deployment/deployConfig.cfg
echo ""
echo "Symfony container port is defined to 8000"

echo ""
echo ""
# Ask user confirmation for server port
read -p "Confirmer le port pour l'application: " -i "$serverPort" -e appPort
# Update the given port if it has changed
sed -i "s/^serverPort=.*$/serverPort=$appPort/" "$gitRepo"/deployment/deployConfig.cfg

# Load new config variables
. "$gitRepo"/deployment/deployConfig.cfg # Override the previous deployConfig.cfg imported

## Ask user confirmation for version number TODO: Research versioning
#read -r -p "Confirmer la version de l'application: " -i "$appVersion" -e version
## Update the given version if it has changed
#sed -i "s/^appVersion=.*$/appVersion=$version/" "$gitRepo"/deployment/deployConfig.cfg

### Replace config variables in files ### TODO: Continue
# .env
sed -i "s/^.*APP_ENV=.*$/APP_ENV=prod/" "$gitRepo"/.env
sed -i "s/^.*APP_DEBUG=.*$/APP_DEBUG=false/" "$gitRepo"/.env
sed -i "s/^.*SECURE_SCHEME=.*$/SECURE_SCHEME=http/" "$gitRepo"/.env
sed -i "s/^.*APP_SECRET=.*$/APP_SECRET=$jwtSecret/" "$gitRepo"/.env
sed -i "s/^.*DATABASE_URL=.*$/DATABASE_URL=\"mysql:\/\/$username:$password@$db_ip:$db_port\/$db_name\"/" "$gitRepo"/.env
sed -i "s/^.*BASE_URL=.*$/BASE_URL=http:\/\/$serverIp:$serverPort\/$applicationDir\/" "$gitRepo"/.env
sed -i "s/^.*URL_ROOT=.*$/URL_ROOT=$applicationDir/" "$gitRepo"/.env
# docker-compose.yaml
sed -i "s/^.*image:.*$/    image: $dockerImageName/" "$gitRepo"/docker-compose.yaml
sed -i "s/^.*container_name:.*$/    container_name: $dockerImageName/" "$gitRepo"/docker-compose.yaml
sed -i "s/^.*- \".*:80\".*$/      - \"$serverPort:80\"/" "$gitRepo"/docker-compose.yaml
sed -i "s/^.*- .\/:.*$/      - .\/:\/var\/www\/$dockerImageName/" "$gitRepo"/docker-compose.yaml
# Dockerfile
sed -i "s/^.*RUN mkdir.*$/RUN mkdir \/var\/www\/$dockerImageName/" "$gitRepo"/Dockerfile
sed -i "s/^.*WORKDIR.*$/WORKDIR \/var\/www\/$dockerImageName\//" "$gitRepo"/Dockerfile
# vhosts.conf
sed -i "s/^.*DocumentRoot.*$/    DocumentRoot \/var\/www\/$dockerImageName\/public/" "$gitRepo"/php/vhosts/vhosts.conf
sed -i "s/^.*<Directory.*public.*$/    <Directory \/var\/www\/$dockerImageName\/public >/" "$gitRepo"/php/vhosts/vhosts.conf
sed -i "s/^.*<Directory.*bundles.*$/    <Directory \/var\/www\/$dockerImageName\/bundles >/" "$gitRepo"/php/vhosts/vhosts.conf

read

##### COMMAND NEEDED TO SETUP THE PROJECT #####
cd $gitRepo
npm install
echo ""
echo "NEXT"
echo ""
composer install
echo ""
echo "NEXT"
echo ""
npm run build
echo ""
echo "TERMINE"
echo ""
cd ..

##### MYSQL DEDICATED DB USER CREATION #####
# Create the dedicated user for this MySQL Database # TODO: MySQL
echo ""
echo "Ajout de l'utilisateur de l'application dans les utilisateurs de la base de données"
mysql -u root -proot -e "CREATE USER '$applicationUsername'@'172.17.0.%' IDENTIFIED BY '$applicationUserPwd';"
mysql -u root -proot -e "GRANT SELECT, UPDATE, INSERT, DELETE, CREATE, DROP, ALTER, REFERENCES ON $dbName.* TO '$applicationUsername'@'172.17.0.%';"
#echo "db.createUser({user: \"$applicationUsername\", pwd: \"$applicationUserPwd\", roles: [{role: \"readWrite\", db: \"$dbName\"}]})" | mongosh -u sadmin -p sadmin admin || echo "L'utilisateur de cette base de données existe déjà"
echo ""
echo ""
