# fastlane-plugin-screenshotslive

Generate app store screenshots via the [Screenshots.live](https://screenshots.live) REST API. Design templates once in the visual editor, then render all device sizes and locales automatically from your Fastlane pipeline.

## Installation

```bash
fastlane add_plugin screenshotslive
```

Or add to your `Gemfile`:

```ruby
gem "fastlane-plugin-screenshotslive"
```

## Usage

```ruby
# Fastfile
lane :screenshots do
  screenshotslive(
    api_key: ENV["SCREENSHOTSLIVE_API_KEY"],
    yaml_config: "./screenshots.yml",
    output_directory: "./fastlane/screenshots"
  )

  # Upload to App Store Connect
  deliver(skip_metadata: true, skip_binary_upload: true)
end
```

## Parameters

| Key | Env Var | Description | Default |
|-----|---------|-------------|---------|
| `api_key` | `SCREENSHOTSLIVE_API_KEY` | Your API key from screenshots.live/app/api-access | Required |
| `yaml_config` | - | Path to your YAML render configuration | Required |
| `output_directory` | - | Where to extract rendered screenshots | `./screenshots` |
| `base_url` | `SCREENSHOTSLIVE_BASE_URL` | Override API URL (for testing) | `https://api.screenshots.live` |

## Output Structure

Screenshots are extracted into Fastlane-compatible folders:

```
screenshots/
  en-US/
    iPhone 6.5/
      screenshot_01.png
      screenshot_02.png
    iPad 12.9/
      screenshot_01.png
      screenshot_02.png
    phoneScreenshots/
      screenshot_01.png
    tenInchScreenshots/
      screenshot_01.png
```

## YAML Configuration

Export your template's YAML config from the Screenshots.live editor, or write one manually:

```yaml
templateId: "your-template-uuid"
locales:
  - code: "en-US"
    overrides:
      headline: "Your App Name"
      subtitle: "The best app ever"
  - code: "de-DE"
    overrides:
      headline: "Ihr App-Name"
      subtitle: "Die beste App aller Zeiten"
```

## Migrating from frameit

Replace your `frameit` call:

```ruby
# Before
frameit(silver: true)

# After
screenshotslive(
  api_key: ENV["SCREENSHOTSLIVE_API_KEY"],
  yaml_config: "./screenshots.yml"
)
```

Screenshots.live gives you everything frameit does plus: dynamic text/image overlays, multi-platform porting, localization via API, and a visual editor for designing templates.

## License

MIT
