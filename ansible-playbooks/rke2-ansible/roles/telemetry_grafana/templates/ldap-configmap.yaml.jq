apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-ldap-config
  namespace: {{ grafana_namespace }}
  labels:
    app: grafana
    component: ldap-config
data:
  ldap.toml: |
    verbose_logging = {{ ldap_verbose_logging | lower }}

    #  LDAP server configuration for editor groups
    [[servers]]
    host = "{{ ldap_host }}"
    port = {{ ldap_port }}
    use_ssl = {{ ldap_use_ssl | lower }}
    start_tls = {{ ldap_start_tls | lower }}
    ssl_skip_verify = {{ ldap_ssl_skip_verify | lower }}
    
    bind_dn = "{{ ldap_bind_dn }}"
    bind_password = "{{ ldap_password }}"
    
    # Search filter for editor groups
    search_filter = "{{ ldap_search_filter_editor }}"
    search_base_dns = [{{ ldap_search_base_dns }}]
    
    [servers.attributes]
    name = "{{ ldap_attr_name }}"
    surname = "{{ ldap_attr_surname }}"
    username = "{{ ldap_attr_username }}"
    member_of = "{{ ldap_attr_member_of }}"
    email = "{{ ldap_attr_email }}"
    
    # Admin group mapping
    [[servers.group_mappings]]
    group_dn = "{{ ldap_admin_group }}"
    org_role = "{{ ldap_admin_role }}"
    org_id = {{ ldap_org_id }}
  
    [servers.group_search]
    base_dn = "{{ ldap_group_base_dn }}"
    filter = "{{ ldap_project_group_admin_pattern }}"

    # Editor group mapping
    [[servers.group_mappings]]
    group_dn = "*"
    org_role = "{{ ldap_project_admin_role }}"
    org_id = {{ ldap_org_id }}

    # LDAP server configuration for admin and viewer groups
    [[servers]]
    host = "{{ ldap_host }}"
    port = {{ ldap_port }}
    use_ssl = {{ ldap_use_ssl | lower }}
    start_tls = {{ ldap_start_tls | lower }}
    ssl_skip_verify = {{ ldap_ssl_skip_verify | lower }}
    
    bind_dn = "{{ ldap_bind_dn }}"
    bind_password = "{{ ldap_password }}"
    
    # Search filter for admin and viewer groups
    search_filter = "{{ ldap_search_filter_admin_and_viewer }}"
    search_base_dns = [{{ ldap_search_base_dns }}]
    
    # Map attributes
    [servers.attributes]
    name = "{{ ldap_attr_name }}"
    surname = "{{ ldap_attr_surname }}"
    username = "{{ ldap_attr_username }}"
    member_of = "{{ ldap_attr_member_of }}"
    email = "{{ ldap_attr_email }}"
    
    # Admin group mapping
    [[servers.group_mappings]]
    group_dn = "{{ ldap_admin_group }}"
    org_role = "{{ ldap_admin_role }}"
    org_id = {{ ldap_org_id }}
    
    # Regular users mapping
    [[servers.group_mappings]]
    group_dn = "{{ ldap_viewer_group }}"
    org_role = "{{ ldap_viewer_role }}"
    org_id = {{ ldap_org_id }}
    
    # Project  group pattern - use group filter instead of wildcard
    [servers.group_search]
    base_dn = "{{ ldap_group_base_dn }}"
    filter = "{{ ldap_project_group_members_pattern }}"

    # Project user mapping
    [[servers.group_mappings]]
    group_dn = "*"  # This applies to groups matched by the filter above
    org_role = "{{ ldap_project_member_role }}"
    org_id = 1


