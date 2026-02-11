# Use "relaxed" rules (https://github.com/rgrove/sanitize)
GOOGLE_MAPS_SANITIZER = Sanitize::Config.merge(Sanitize::Config::RELAXED, { 
  elements: ['iframe'], # Only allow iframes
  attributes: { 
    'iframe' => ['src', 'width', 'height', 'style', 'allowfullscreen', 'loading', 'referrerpolicy']
    # Allow only these parameteres in iframe
  },
  protocols: {
    'iframe' => {
      'src' => ['https']
      # Only allow https for src
    }
  }
})
