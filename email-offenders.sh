rss=`curl http://plaintextoffenders.com/rss --silent`

# Go over latest domains
for domain in $(echo $rss | ./xidel - --xpath "//item/description" --quiet | awk -F'<p>' '{ print $2; }' | sed -E 's/(<br\/?>)?<\/p>//' | tr -d '  ' | tr ',' '\n')
do

	# If we already sent them a notice, don't do it again
	if grep -Fq "$domain " pto-email.csv;
	then
		continue
	fi

    echo -n "Looking into $domain: " >&2

	# Search for any email address in the whois record for this site
	emailAddressesJson=`whois $domain | grep -i Email | grep @ | grep -i $domain | sed -E 's/^.+[ :]([^ :@]+@[^ ]+)$/{"email":"\1"}/g' | sort | uniq -i | tr '\n' ',' | sed 's/,$//'`

	if [ -n "$emailAddressesJson" ];
	then
		postUrl=`echo $rss | ./xidel - --xpath "//item[contains(description/text(), '$domain')]/link" --quiet`

		echo "Emailing $emailAddressesJson... " >&2
		
		payload=" \
            { \
                'key': '<TODO: ADD YOUR KEY HERE>', \
                'template_name': 'plain-text-offenders-notification', \
                'template_content': [ \
                    { 'name': 'domain', 'content': '$domain' }, \
                    { 'name': 'submission', 'content': '$postUrl' } \
                ], \
                'message': { \
                    'to': [ $emailAddressesJson ], \
                    'important': true, \
                    'bcc_address': 'plaintextoffenders@gmail.com', \
                    'merge_language': 'handlebars', \
                    'global_merge_vars': [ \
                        { 'name': 'domain', 'content': '$domain' }, \
                        { 'name': 'submission', 'content': '$postUrl' } \
                    ], \
                    'preserve_recipients': true \
                }, \
                'async': false \
            } \
		"

		echo $payload | sed -E 's/'"'"'/"/g' | curl -A 'Mandrill-Curl/1.0' -d @- 'https://mandrillapp.com/api/1.0/messages/send-template.json'
	
    	# report success
    	echo "$domain " >> pto-email.csv

        echo ""
        echo "Done, now give me a few seconds. I gotta rest here... *phew*"
        sleep 5
    else
        echo "No domain emails found in the whois record."
    fi

    echo ""

done

echo ""
echo ""
echo ""
echo ""
