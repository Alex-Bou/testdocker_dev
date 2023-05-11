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
# .env -> DATABASE_URL
sed -i "s/^.*DATABASE_URL=.*$/DATABASE_URL=\"mysql://$username:$password@$db_ip:$db_port/$db_name\"/" "$gitRepo"/.env


##### COMMAND NEEDED TO SETUP THE PROJECT #####
# npm install
# npm run watch # TODO: Run async
# composer install

##### MYSQL DEDICATED DB USER CREATION #####
# Create the dedicated user for this MySQL Database # TODO: MySQL
echo ""
echo "Ajout de l'utilisateur de l'application dans les utilisateurs de la base de données"
#echo "db.createUser({user: \"$applicationUsername\", pwd: \"$applicationUserPwd\", roles: [{role: \"readWrite\", db: \"$dbName\"}]})" | mongosh -u sadmin -p sadmin admin || echo "L'utilisateur de cette base de données existe déjà"
echo ""
echo ""
