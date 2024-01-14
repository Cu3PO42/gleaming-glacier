use serde::de::{self, Deserializer, Unexpected, Visitor};
use serde::Deserialize;
use std::fmt;
use regex::Regex;
use std::path::{Path, PathBuf};
use std::collections::HashMap;
use clap::Parser;
use anyhow::{Context, anyhow};
use gray_matter::{Matter, engine::YAML};
use std::str::FromStr;

#[derive(Debug, Clone, Copy)]
struct Color(u8, u8, u8);

#[derive(Debug, Clone, thiserror::Error)]
enum ColorParseError {
    #[error("invalid length: expected 6, got {0}")]
    InvalidLength(usize),
    #[error("invalid hex value: {0}")]
    InvalidValue(String),
}
impl FromStr for Color {
    type Err = ColorParseError;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        if s.len() != 6 {
            return Err(ColorParseError::InvalidLength(s.len()));
        }

        let r = u8::from_str_radix(&s[0..2], 16).map_err(|_| ColorParseError::InvalidValue(s[0..2].to_string()))?;
        let g = u8::from_str_radix(&s[2..4], 16).map_err(|_| ColorParseError::InvalidValue(s[2..4].to_string()))?;
        let b = u8::from_str_radix(&s[4..6], 16).map_err(|_| ColorParseError::InvalidValue(s[4..6].to_string()))?;

        Ok(Color(r, g, b))
    }
}


impl<'de> Deserialize<'de> for Color {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct ColorVisitor;

        impl<'de> Visitor<'de> for ColorVisitor {
            type Value = Color;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("a string in the format rrggbb")
            }

            fn visit_str<E>(self, value: &str) -> Result<Color, E>
            where
                E: de::Error,
            {
                if value.len() != 6 {
                    return Err(E::invalid_length(value.len(), &self));
                }

                Color::from_str(value).map_err(|_| E::invalid_value(Unexpected::Str(value), &self))
            }
        }

        deserializer.deserialize_str(ColorVisitor)
    }
}

#[derive(Debug, Clone, Copy, Deserialize)]
enum Format {
    Hex,
}
impl FromStr for Format {
    type Err = anyhow::Error;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "hex" => Ok(Format::Hex),
            _ => Err(anyhow!("Unknown format: {}", s)),
        }
    }
}

#[derive(Debug, Clone, Deserialize)]
struct Frontmatter {
    defines: HashMap<String, String>,
}

#[derive(Debug, Parser)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Name of the template file
    pub template: PathBuf,

    /// Name of the palette file
    pub palette: PathBuf,
    
    /// Assign the given color values for the specified names.
    /// The format is `NAME=COLOR`, where `COLOR` is a hex value in the format `rrggbb`.
    /// Note that there is no leading `#`.
    /// 
    /// These overrides are applied both to the palette and after the frontmatter defines.
    #[arg(short, long="override", num_args = 1, value_parser = parse_key_val::<String, Color>)]
    pub overrides: Vec<(String, Color)>,
}

fn parse_key_val<T, U>(s: &str) -> Result<(T, U), Box<dyn std::error::Error + Send + Sync>>
where
    T: std::str::FromStr,
    T::Err: std::error::Error + Send + Sync + 'static,
    U: std::str::FromStr,
    U::Err: std::error::Error + Send + Sync + 'static,
{
    let pos = s
        .find('=')
        .ok_or_else(|| format!("invalid KEY=value: no `=` found in `{}`", s))?;
    Ok((s[..pos].parse()?, s[pos + 1..].parse()?))
}

type Palette = HashMap<String, Color>;

#[derive(Debug, Clone, Deserialize)]
struct PaletteFile {
    pub semantic: Palette,
    pub colors: Palette,
    pub accents: Palette,
}

fn load_palette(path: &Path) -> anyhow::Result<Palette> {
    let content = std::fs::read_to_string(path).context("Failed to read palette file")?;
    let palette_file: PaletteFile = serde_json::from_str(&content).context("Failed to parse palette file")?;
    let mut palette = palette_file.semantic;
    palette.extend(palette_file.colors);
    palette.extend(palette_file.accents);

    Ok(palette)
}

fn apply_overrides(palette: &mut Palette, overrides: &[(String, Color)]) -> anyhow::Result<()> {
    for (name, color) in overrides {
        palette.insert(name.clone(), *color);
    }
    Ok(())
}

fn replace_colors(template: &str, palette: &Palette) -> anyhow::Result<String> {
    let re = Regex::new(r"⟨([^:⟩]+):([^⟩]+)⟩")?;
    let mut result = String::with_capacity(template.len());
    let mut last_end = 0;
    for caps in re.captures_iter(template) {
        let m = caps.get(0).unwrap();
        result.push_str(&template[last_end..m.start()]);
        let name = caps.get(1).unwrap().as_str();
        let format = caps.get(2).unwrap().as_str();
        let color = palette.get(name).ok_or_else(|| anyhow!("Unknown color: {}", name))?;
        result.push_str(&format_color(*color, Format::from_str(format)?));
        last_end = m.end();
    }
    result.push_str(&template[last_end..]);
    Ok(result)
}

fn format_color(color: Color, fmt: Format) -> String {
    match fmt {
        Format::Hex => format!("{:02x}{:02x}{:02x}", color.0, color.1, color.2),
    }
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();

    let template = std::fs::read_to_string(&args.template).context(format!("Failed to read template file: {}", args.template.to_string_lossy()))?;
    let mut palette = load_palette(&args.palette)?;
    apply_overrides(&mut palette, &args.overrides)?;

    let matter = Matter::<YAML>::new();
    let entity = matter.parse(&template);

    let frontmatter = entity.data.map(|data| data.deserialize::<Frontmatter>()).transpose().context("Failed to parse frontmatter")?;
    if let Some(frontmatter) = frontmatter {
        for (name, value) in frontmatter.defines {
            let color = palette.get(&value).ok_or_else(|| anyhow!("Unknown color: {}", value))?;
            palette.insert(name, *color);
        }
    }
    apply_overrides(&mut palette, &args.overrides)?;

    let result = replace_colors(&entity.content, &palette)?;
    println!("{}", result);

    Ok(())
}
