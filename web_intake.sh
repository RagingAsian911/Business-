\
#!/usr/bin/env bash
set -euo pipefail

echo "---- WEB INTAKE INSTALL START ----"

DOMAIN="${DOMAIN_MAIN:-bbwtemplesite.org.uk}"
DOCROOT="/var/www/${DOMAIN}"

mkdir -p "$DOCROOT"
cat >"${DOCROOT}/index.php" <<'PHP'
<?php
date_default_timezone_set('UTC');
$log = '/var/log/leads.csv';
$ok = false;
$msg = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $name  = trim($_POST['name'] ?? '');
  $phone = trim($_POST['phone'] ?? '');
  $email = trim($_POST['email'] ?? '');
  $note  = trim($_POST['note'] ?? '');

  if ($name !== '' && ($phone !== '' || $email !== '')) {
    $row = [
      date('c'),
      str_replace(["\n","\r"], ' ', $name),
      str_replace(["\n","\r"], ' ', $phone),
      str_replace(["\n","\r"], ' ', $email),
      str_replace(["\n","\r"], ' ', $note),
      $_SERVER['REMOTE_ADDR'] ?? ''
    ];
    $fp = fopen($log, 'a');
    if ($fp) {
      fputcsv($fp, $row);
      fclose($fp);
      $ok = true;
      $msg = 'Lead received. We will contact you shortly.';
    } else {
      $msg = 'Server error writing lead.';
    }
  } else {
    $msg = 'Please provide a name and a phone or email.';
  }
}
?>
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Business Intake</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body{font-family:system-ui,Arial;margin:24px;max-width:720px}
    input,textarea{width:100%;padding:10px;margin:8px 0}
    button{padding:10px 14px}
    .ok{color:green}
    .bad{color:#b00020}
  </style>
</head>
<body>
  <h1>Contact / Lead Intake</h1>
  <p>Submit your info and we’ll call you back.</p>

  <?php if($msg): ?>
    <p class="<?php echo $ok ? 'ok' : 'bad'; ?>"><?php echo htmlspecialchars($msg); ?></p>
  <?php endif; ?>

  <form method="post">
    <label>Name</label>
    <input name="name" required>
    <label>Phone</label>
    <input name="phone" placeholder="+1...">
    <label>Email</label>
    <input name="email" type="email" placeholder="you@example.com">
    <label>What do you need?</label>
    <textarea name="note" rows="5"></textarea>
    <button type="submit">Send</button>
  </form>
</body>
</html>
PHP

# permissions for lead log
touch /var/log/leads.csv
chown www-data:www-data /var/log/leads.csv
chmod 664 /var/log/leads.csv

# Apache vhost
cat >"/etc/apache2/sites-available/${DOMAIN}.conf" <<EOF
<VirtualHost *:80>
  ServerName ${DOMAIN}
  DocumentRoot ${DOCROOT}
  <Directory ${DOCROOT}>
    AllowOverride All
    Require all granted
  </Directory>
  ErrorLog \${APACHE_LOG_DIR}/${DOMAIN}-error.log
  CustomLog \${APACHE_LOG_DIR}/${DOMAIN}-access.log combined
</VirtualHost>
EOF

a2enmod rewrite || true
a2dissite 000-default >/dev/null 2>&1 || true
a2ensite "${DOMAIN}.conf"

systemctl enable apache2
systemctl restart apache2

echo "---- WEB INTAKE INSTALL END ----"
