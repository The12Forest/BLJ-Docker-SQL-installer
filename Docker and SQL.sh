#wsl --install Ubuntu-20.04


if [ -n "$SUDO_USER" ]; then
  echo "ERROR: do not run this script with sudo" >&2
  exit 1
fi

clear
while true; do
    read -p "Do you want to install Docker:                     " YesORNoD
    if [[ "$YesORNoD" =~ ^(Yes|No)$ ]]; then
        break
    else
        echo "Invalid input. Please enter 'Yes' or 'No'."
    fi
done
if [ "$YesORNoD" == "No" ]; then
  clear
  exit 1
fi
while true; do
    read -p "Do you want to install an SQL Server on Docker:    " YesORNoS
    if [[ "$YesORNoS" =~ ^(Yes|No)$ ]]; then
        break
    else
        echo "Invalid input. Please enter 'Yes' or 'No'."
    fi
done

if [ "$YesORNoS" == "Yes" ]; then
  clear
  echo Now you are in the Password Stage!
  echo
  while true; do
    read -p "Now you have to set a Password for the SQL Server: " passwd
    echo
    read -p "Please retype the password: " passwd2
    echo
  if [ "$passwd" = "$passwd2" ] && [ -n "$passwd" ]; then
    break
  fi
  echo "Passwords do not match or empty. Try again."
done
  clear
fi


sudo apt-get update

# Add Docker’s official GPG key
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker’s official Ubuntu repo
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
sudo apt-get update


sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo usermod -aG docker $USER


if [ "$YesORNoS" == "Yes" ]; then
  clear
  echo Starting Container

  cd ~

  sudo mkdir -p ~/BLJ-SQL

  sudo chmod -R 777 ~/BLJ-SQL

  sudo docker run -d \
    --name sqlserver \
    --restart unless-stopped \
    --network host \
    -e "ACCEPT_EULA=Y" \
    -e "MSSQL_SA_PASSWORD=$passwd" \
    -e "MSSQL_PID=Express" \
    -v ~/BLJ-SQL:/var/opt/mssql \
    --health-cmd '/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Admin@123" -Q "SELECT 1" || exit 1' \
    --health-interval=10s \
    --health-timeout=3s \
    --health-retries=10 \
    --health-start-period=10s \
    mcr.microsoft.com/mssql/server:2022-latest

  sudo docker ps

  ipaddr=$(ip -4 addr show eth0 | awk '/inet /{print $2}' | cut -d/ -f1)

  clear

  echo Der SQL Server ist erfolgreich installier!
  echo Nun kannst du dich darauf verbinden.
  echo
  echo Die Anmeldedaten sind:
  echo "  Address:    $ipaddr, 1443"
  echo "  User:       sa"
  echo "  Passwd:     $password"
  echo
  echo
  echo PS: Wenn du deinen PC neustartest wird der Server gestoppt, um ihn wider zu starten öffne einfach kurtz WSL.
fi