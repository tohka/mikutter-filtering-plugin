# -*- encoding: utf-8 -*-

Plugin.create(:filtering) do

	# 特定の単語を含むんだツイートをミュート
	mute_words = ["饅頭"]

	# 特定のユーザによってつぶやかれた / RT されたツイートをミュート
	mute_users = ["wwwww_BOT"]

	# 特定のユーザによって RT されたツイートをミュート
	mute_RT_by_users = []

	# 特定のユーザによって非公式 RT / QT されたツイートをミュート
	mute_QT_by_users = []



	is_checked_no_retweet = false

	filter_update do |service, msgs|
		unless is_checked_no_retweet
			res = service.twitter.query!('friendships/no_retweet_ids')
			if res.code == '200'
				JSON.parse(res.body).each do |user|
					mute_RT_by_users << user
					mute_QT_by_users << user
				end
			end
			is_checked_no_retweet = true
		end

		msgs = msgs.select do |msg|
			is_remaining = true
			if is_remaining
				is_remaining = ! mute_words.any? do |word|
					msg[:message].include?(word)
				end
			end
			if is_remaining
				is_remaining = ! mute_users.any? do |user|
					msg[:user][:id_str] == user.to_s ||
							msg[:user][:screen_name] == user ||
							(! msg[:retweeted_status].nil? &&
							(msg[:retweeted_status][:user][:id_str] == user.to_s ||
							msg[:retweeted_status][:user][:screen_name] == user))
				end
			end
			if is_remaining
				is_remaining = ! mute_RT_by_users.any? do |user|
					(msg[:user][:id_str] == user.to_s ||
							msg[:user][:screen_name] == user) &&
							(! msg[:retweeted_status].nil?)
				end
			end
			if is_remaining
				is_remaining = ! mute_QT_by_users.any? do |user|
					(msg[:user][:id_str] == user.to_s ||
							msg[:user][:screen_name] == user) &&
							(! ["RT", "QT"].any?{|rt| msg[:message].include?(rt)})
				end
			end
			is_remaining
		end
		[service, msgs]
	end
end

