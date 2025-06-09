echo "env:" > env-values.yaml
awk -F= '!/^#/ && NF==2 && $1 ~ /^[A-Za-z_][A-Za-z0-9_]*$/ {
    gsub(/"/, "", $2);
    print "  " $1 ": \"" $2 "\""
}' .env >> env-values.yaml