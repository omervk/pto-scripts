rss=`curl http://plaintextoffenders.com/rss --silent`

# Go over latest domains
for domain in $(echo $rss | ./xidel - --xpath "//item/description" --quiet | awk -F'<p>' '{ print $2; }' | sed -E 's/(<br\/?>)?<\/p>//' | tr -d '  ' | tr ',' '\n')
do

	# If we already sent them a notice, don't do it again
	if grep -Fq "$domain," pto-twitter.csv;
	then
		continue
	fi

        echo "Looking into $domain..." >&2

	# Bing search for their twitter handle. Use both domain: and site: modifiers, find only handles and make sure we don't have duplicate results
	for twitterHandle in $({ \
		./xidel http://www.bing.com/search?q=%22$domain%22+domain:twitter.com --extract "//li[@class='b_algo']//cite" --quiet && \
		./xidel http://www.bing.com/search?q=%22$domain%22+site:twitter.com --extract "//li[@class='b_algo']//cite" --quiet; } | \
		grep -E '^https?://(www\.)?twitter\.com/[^/]+$' | \
		sed -E 's/.+\/(.+)/@\1/' | \
                sort | uniq -i)
	do
		echo -n "Found $twitterHandle... " >&2

		# Find out if their url on twitter is the same as the one we're searching for. Only look for top level domains.
		urlFromTwitter=`t whois $twitterHandle | \
		                grep -E '^URL[ ]+(https?\:\/\/)?(www\.)?([^\/]+)\/?$' | \
		                sed -E 's/^URL[ ]+(https?\:\/\/)?(www\.)?([^\/]+)(\/.*)?$/\3/' | \
		                tr '[:upper:]' '[:lower:]'`

		if [ "$urlFromTwitter" == "" ]; then
			echo "No URL" >&2
		else
			echo -n "URL from Twitter is $urlFromTwitter... " >&2

			if [ "$urlFromTwitter" == "$domain" ]; then
				echo "It's a match! Tweeting..." >&2

				# find the post's url
				link=`echo $rss | ./xidel - --xpath "//item/description[contains(., '$domain')]/following-sibling::link" --quiet`

				t update ".$twitterHandle You are featured as an offender at $link. Please read http://plaintextoffenders.com/faq/non-devs for why."

				# report success
				echo "$domain,$twitterHandle" >> pto-twitter.csv

				echo "OK, give me a minute. I gotta rest here... *phew*"
				sleep 60
			else
				echo "Yeah, no." >&2
			fi
		fi
	done

	echo -n "Getting ready... 3 " >&2

	sleep 1

        echo -n "2 " >&2

        sleep 1

        echo -n "1" >&2

        sleep 1

	echo ". Let's go!"
	echo ""

done

echo ""
echo ""
echo ""
echo ""
