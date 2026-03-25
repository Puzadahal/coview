class AppTexts {
  AppTexts._();

  static const Map<String, Map<String, String>> _text = {
    'en': {
      'home': 'Home',
      'about': 'About Us',
      'recommendations': 'Recommendations',
      'language': 'Language',
      'heroTitle': 'Watch together\nfrom anywhere',
      'heroSubtitle':
          'Create a room, share a link, and stream with synchronized playback and live chat.',
      'startWatching': 'Start Watching',
      'joinExisting': 'Join Existing Room',
      'howItWorks': 'How it works',
      'aboutTitle': 'About Us',
      'aboutDesc':
          'SyncView helps friends and families watch together remotely with synced video playback, invite-based rooms, and real-time chat in one place.',
      'trending': 'Trending recommendations',
      'trendingSub': 'Latest picks to enjoy with your room.',
      'footer': 'Watch together. Stay together.',
      'aboutPageTitle': 'About SyncView',
      'aboutPageHeading': 'Watch parties, simplified',
      'aboutPageSub':
          'SyncView helps friends and families watch together from anywhere with shared rooms, invite links, and live chat.',
      'whatWeFocus': 'What we focus on',
      'ourVision': 'Our vision',
      'recommendationsPageTitle': 'Recommendations',
      'recommendationsPageHeading': 'Trending to watch with your room',
      'recommendationsPageSub':
          'Pick one and start a shared watch session in seconds.',
      'watchWithFriends': 'Watch with friends',
    },
    'ne': {
      'home': 'होम',
      'about': 'हाम्रो बारेमा',
      'recommendations': 'सिफारिसहरू',
      'language': 'भाषा',
      'heroTitle': 'जहाँसुकै\nसँगै हेरौं',
      'heroSubtitle':
          'रूम बनाउनुहोस्, लिंक सेयर गर्नुहोस् र सिङ्क भिडियोसँगै लाइभ च्याट गर्नुहोस्।',
      'startWatching': 'हेर्न सुरु गर्नुहोस्',
      'joinExisting': 'अवस्थित रूममा जोडिनुहोस्',
      'howItWorks': 'कसरी काम गर्छ',
      'aboutTitle': 'हाम्रो बारेमा',
      'aboutDesc':
          'SyncView ले साथीभाइ र परिवारलाई टाढाबाट पनि सँगै हेर्ने अनुभव दिन्छ।',
      'trending': 'चल्तीका सिफारिसहरू',
      'trendingSub': 'तपाईंको रूमका लागि नयाँ छनोट।',
      'footer': 'सँगै हेरौं। जोडिएर बसौं।',
      'aboutPageTitle': 'SyncView बारे',
      'aboutPageHeading': 'वाच पार्टी, अझ सजिलो',
      'aboutPageSub':
          'SyncView ले साझा रूम, निमन्त्रणा लिंक र लाइभ च्याटमार्फत साथमा हेर्न सजिलो बनाउँछ।',
      'whatWeFocus': 'हामी केमा केन्द्रित छौं',
      'ourVision': 'हाम्रो लक्ष्य',
      'recommendationsPageTitle': 'सिफारिसहरू',
      'recommendationsPageHeading': 'तपाईंको रूमका लागि ट्रेन्डिङ',
      'recommendationsPageSub': 'एक छनोट गर्नुहोस् र साथीहरूसँग हेर्न सुरु गर्नुहोस्।',
      'watchWithFriends': 'साथीसँग हेर्नुहोस्',
    },
    'hi': {
      'home': 'होम',
      'about': 'हमारे बारे में',
      'recommendations': 'सुझाव',
      'language': 'भाषा',
      'heroTitle': 'कहीं से भी\nसाथ में देखें',
      'heroSubtitle':
          'रूम बनाएं, लिंक शेयर करें और सिंक वीडियो के साथ लाइव चैट करें।',
      'startWatching': 'देखना शुरू करें',
      'joinExisting': 'मौजूदा रूम जॉइन करें',
      'howItWorks': 'यह कैसे काम करता है',
      'aboutTitle': 'हमारे बारे में',
      'aboutDesc':
          'SyncView दोस्तों और परिवार को दूर रहते हुए भी साथ देखने का अनुभव देता है।',
      'trending': 'ट्रेंडिंग सुझाव',
      'trendingSub': 'आपके रूम के लिए नई पसंद।',
      'footer': 'साथ देखें। जुड़े रहें।',
      'aboutPageTitle': 'SyncView के बारे में',
      'aboutPageHeading': 'वॉच पार्टी, आसान तरीके से',
      'aboutPageSub':
          'SyncView साझा रूम, इनवाइट लिंक और लाइव चैट के साथ साथ देखने का अनुभव देता है।',
      'whatWeFocus': 'हमारा फोकस',
      'ourVision': 'हमारा विज़न',
      'recommendationsPageTitle': 'सुझाव',
      'recommendationsPageHeading': 'आपके रूम के लिए ट्रेंडिंग',
      'recommendationsPageSub': 'एक चुनें और दोस्तों के साथ देखना शुरू करें।',
      'watchWithFriends': 'दोस्तों के साथ देखें',
    },
  };

  static String tr(String languageCode, String key) {
    return _text[languageCode]?[key] ?? _text['en']![key] ?? key;
  }
}

