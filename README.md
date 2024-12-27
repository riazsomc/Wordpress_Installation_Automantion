## Automation Script for WordPress Installation
This Bash script automates the installation process of WordPress on an Apache web server with MySQL database on Ubuntu. It also configures SSL using Let's Encrypt for secure communication.

### Prerequisites
* Ubuntu server with sudo privileges
* A domain name pointing to the server's IP address
* Basic familiarity with the command line and server administration
### Usage
Clone or download this repository to your Ubuntu server:

```bash
git clone https://github.com/riazsomc/Wordpress_Installation_Automantion.git
```
Navigate to the directory containing the script:

```bash
cd Wordpress_Installation_Automantion
```
Make the script executable:

```bash
chmod +x install_wordpress.sh
```
Edit the script variables in install_wordpress.sh according to your environment:

```bash
wordpress_db="your_database_name"
db_user="your_database_user"
db_password="your_database_password"
virtualhost_name="your_domain_name"
```
Execute the script:

```bash
./install_wordpress.sh
```
Follow the on-screen instructions to complete the installation. After the script finishes, you can access your WordPress site via your domain name.

### Important Notes
* This script is optimized for PHP 8.2. Ensure that it meets your requirements before running the script.
* Make sure to configure fail2ban manually for enhanced security.
* It's recommended to review the script and understand each step before running it in a production environment.
* For any issues or questions, feel free to open an issue in this repository.
### Credits
This script is inspired by various sources and has been customized for ease of use and compatibility with Ubuntu servers.
