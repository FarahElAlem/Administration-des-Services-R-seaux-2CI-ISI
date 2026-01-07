#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Module 05: Configuration des Virtual Hosts
# ═══════════════════════════════════════════════════════════

module_vhosts_install() {
    print_step "5" "8" "Configuration des Virtual Hosts"
    save_log_section "vhosts"
    timer_start
    
    # Charger templating
    source "$SCRIPT_DIR/lib/templating.sh"
    
    # Vérifier qu'on a au moins un vhost
    if [ "$VHOST_COUNT" -eq 0 ]; then
        print_warning "Aucun virtual host défini dans config.yaml"
        print_substep_last "Durée: $(timer_end)"
        end_log_section "vhosts"
        return 0
    fi
    
    # Déterminer la version PHP
    export PHP_VERSION=$(get_php_version)
    if [ -z "$PHP_VERSION" ]; then
        print_warning "PHP non détecté, utilisation de 8.4 par défaut"
        export PHP_VERSION="8.4"
    fi
    
    print_substep "$VHOST_COUNT virtual host(s) à créer"
    echo ""
    
    # ─────────────────────────────────────────────────────────
    # Créer chaque virtual host
    # ─────────────────────────────────────────────────────────
    
    for i in $(seq 0 $((VHOST_COUNT - 1))); do
        # Charger les variables de ce vhost
        vhost_name_var="VHOST_${i}_NAME"
        vhost_enabled_var="VHOST_${i}_ENABLED"
        vhost_domain_var="VHOST_${i}_DOMAIN"
        vhost_type_var="VHOST_${i}_TYPE"
        vhost_root_var="VHOST_${i}_ROOT"
        
        vhost_name="${!vhost_name_var}"
        vhost_enabled="${!vhost_enabled_var}"
        vhost_domain="${!vhost_domain_var}"
        vhost_type="${!vhost_type_var}"
        vhost_root="${!vhost_root_var}"
        
        # Vérifier que le vhost est activé
        if [ "$vhost_enabled" != "true" ]; then
            print_substep "⊘ $vhost_name désactivé, ignoré"
            continue
        fi
        
        # Vérifier que le domaine est défini
        if [ -z "$vhost_domain" ]; then
            print_warning "Domaine vide pour $vhost_name, ignoré"
            continue
        fi
        
        print_substep "Création VHost: $vhost_domain ($vhost_type)"
        
        # ─────────────────────────────────────────────────────────
        # 1. Créer la structure de répertoires
        # ─────────────────────────────────────────────────────────
        
        mkdir -p "$vhost_root"
        chown -R www-data:www-data "$vhost_root"
        chmod -R 755 "$vhost_root"
        
        # ─────────────────────────────────────────────────────────
        # 2. Générer la page d'accueil depuis template
        # ─────────────────────────────────────────────────────────
        
        # Choisir le bon template selon le type
        if [ "$vhost_type" = "php" ]; then
            if [ -f "$SCRIPT_DIR/templates/html/portal-rh.html.template" ]; then
                template_html="$SCRIPT_DIR/templates/html/portal-rh.html.template"
            elif [ -f "$SCRIPT_DIR/templates/html/blog.html.template" ]; then
                template_html="$SCRIPT_DIR/templates/html/blog.html.template"
            else
                template_html="$SCRIPT_DIR/templates/html/site-public.html.template"
            fi
        else
            template_html="$SCRIPT_DIR/templates/html/site-public.html.template"
        fi
        
        # Générer index.html
        if [ -f "$template_html" ]; then
            generate_from_template \
                "$template_html" \
                "${vhost_root}/index.html" \
                "SITE_TITLE" "${vhost_name^}" \
                "STUDENT_FIRSTNAME" "$STUDENT_FIRSTNAME" \
                "STUDENT_LASTNAME" "$STUDENT_LASTNAME" \
                "STUDENT_FORMATION" "$STUDENT_FORMATION" \
                "SERVER_IP" "$SERVER_IP" \
                "SERVER_HOSTNAME" "$SERVER_HOSTNAME"
        else
            # Fallback : créer une page simple
            cat > "${vhost_root}/index.html" << HTMLFALLBACK
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>${vhost_name^}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            text-align: center;
            background: rgba(255,255,255,0.1);
            padding: 60px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
        }
        h1 { font-size: 3em; margin-bottom: 20px; }
        p { font-size: 1.2em; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 ${vhost_name^}</h1>
        <p>Type: ${vhost_type}</p>
        <p>Domaine: ${vhost_domain}</p>
        <p>Par: $STUDENT_FIRSTNAME $STUDENT_LASTNAME</p>
        <p>$STUDENT_FORMATION</p>
    </div>
</body>
</html>
HTMLFALLBACK
        fi
        
        chown www-data:www-data "${vhost_root}/index.html"
        chmod 644 "${vhost_root}/index.html"
        
        # ─────────────────────────────────────────────────────────
        # 3. Créer info.php si site PHP
        # ─────────────────────────────────────────────────────────
        
        if [ "$vhost_type" = "php" ]; then
            if [ -f "$SCRIPT_DIR/templates/html/info.php.template" ]; then
                generate_from_template \
                    "$SCRIPT_DIR/templates/html/info.php.template" \
                    "${vhost_root}/info.php" \
                    "STUDENT_FIRSTNAME" "$STUDENT_FIRSTNAME" \
                    "STUDENT_LASTNAME" "$STUDENT_LASTNAME"
            else
                cat > "${vhost_root}/info.php" << 'PHPINFO'
<?php
phpinfo();
?>
PHPINFO
            fi
            
            chown www-data:www-data "${vhost_root}/info.php"
            chmod 644 "${vhost_root}/info.php"
        fi
        
        # ─────────────────────────────────────────────────────────
        # 4. Générer la config Nginx
        # ─────────────────────────────────────────────────────────
        
        # Choisir le template Nginx
        if [ "$vhost_type" = "php" ]; then
            template_nginx="$SCRIPT_DIR/templates/nginx/vhost-php.conf.template"
        else
            template_nginx="$SCRIPT_DIR/templates/nginx/vhost-static.conf.template"
        fi
        
        # Nom du fichier de config (remplacer les caractères spéciaux)
        config_name=$(echo "$vhost_name" | tr '.' '_' | tr '-' '_')
        
        if [ -f "$template_nginx" ]; then
            generate_from_template \
                "$template_nginx" \
                "/etc/nginx/sites-available/${config_name}.conf" \
                "DOMAIN" "$vhost_domain" \
                "ROOT" "$vhost_root" \
                "NAME" "$vhost_name" \
                "PHP_VERSION" "$PHP_VERSION"
        else
            # Fallback : créer config basique
            if [ "$vhost_type" = "php" ]; then
                cat > "/etc/nginx/sites-available/${config_name}.conf" << NGINXPHP
server {
    listen 80;
    server_name ${vhost_domain};
    root ${vhost_root};
    index index.php index.html;

    access_log /var/log/nginx/${config_name}_access.log;
    error_log /var/log/nginx/${config_name}_error.log;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
NGINXPHP
            else
                cat > "/etc/nginx/sites-available/${config_name}.conf" << NGINXSTATIC
server {
    listen 80;
    server_name ${vhost_domain};
    root ${vhost_root};
    index index.html;

    access_log /var/log/nginx/${config_name}_access.log;
    error_log /var/log/nginx/${config_name}_error.log;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
NGINXSTATIC
            fi
        fi
        
        # Activer le site
        ln -sf "/etc/nginx/sites-available/${config_name}.conf" "/etc/nginx/sites-enabled/"
        
        print_substep "✓ $vhost_domain configuré"
    done
    
    # ─────────────────────────────────────────────────────────
    # Tester la config Nginx
    # ─────────────────────────────────────────────────────────
    
    echo ""
    print_substep "Test de la configuration Nginx..."
    
    if nginx -t >/dev/null 2>&1; then
        print_substep "✓ Configuration valide"
    else
        print_error "Configuration Nginx invalide"
        nginx -t
        return 1
    fi
    
    # ─────────────────────────────────────────────────────────
    # Recharger Nginx
    # ─────────────────────────────────────────────────────────
    
    print_substep "Rechargement de Nginx..."
    systemctl reload nginx
    
    if [ $? -eq 0 ]; then
        print_substep "✓ Nginx rechargé"
    else
        print_error "Échec du rechargement Nginx"
        return 1
    fi
    
    local duration=$(timer_end)
    print_substep_last "Durée: $duration"
    print_success "$VHOST_COUNT Virtual Host(s) créé(s)"
    
    end_log_section "vhosts"
    return 0
}
