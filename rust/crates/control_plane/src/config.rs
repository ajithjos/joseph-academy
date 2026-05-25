use std::env;
use std::path::PathBuf;

use anyhow::{Context, anyhow};

#[derive(Debug, Clone)]
pub struct AppConfig {
    pub bind_address: String,
    pub database_url: String,
    pub content_root: PathBuf,
    pub bootstrap_path: PathBuf,
    pub artifacts_root: PathBuf,
    pub exports_root: PathBuf,
    pub auto_bootstrap: bool,
    pub frontend_public_url: Option<String>,
    pub content_public_url: Option<String>,
}

impl AppConfig {
    pub fn from_env() -> anyhow::Result<Self> {
        Ok(Self {
            bind_address: env::var("CORNERSTONE_BIND_ADDRESS").unwrap_or_else(|_| "0.0.0.0:8787".to_string()),
            database_url: env::var("CORNERSTONE_DATABASE_URL")
                .or_else(|_| env::var("DVI_CONTROL_PLANE_DATABASE_URL"))
                .context("CORNERSTONE_DATABASE_URL must be set")?,
            content_root: required_path("CORNERSTONE_CONTENT_ROOT", "content")?,
            bootstrap_path: env_path_or_default(
                "CORNERSTONE_BOOTSTRAP_FILE",
                PathBuf::from("deploy/config/runtime_defaults/identity_bootstrap.yaml"),
            )?,
            artifacts_root: env_path_or_default(
                "CORNERSTONE_ARTIFACTS_ROOT",
                PathBuf::from("scratchpad/dev/local/data/01/artifacts"),
            )?,
            exports_root: env_path_or_default(
                "CORNERSTONE_EXPORTS_ROOT",
                PathBuf::from("scratchpad/dev/local/data/01/exports"),
            )?,
            auto_bootstrap: env::var("CORNERSTONE_AUTO_BOOTSTRAP")
                .ok()
                .map(|value| parse_bool(&value))
                .transpose()?
                .unwrap_or(true),
            frontend_public_url: optional_env("CORNERSTONE_FRONTEND_PUBLIC_URL"),
            content_public_url: optional_env("CORNERSTONE_CONTENT_PUBLIC_URL"),
        })
    }
}

fn optional_env(key: &str) -> Option<String> {
    env::var(key).ok().and_then(|value| {
        let trimmed = value.trim();
        if trimmed.is_empty() {
            None
        } else {
            Some(trimmed.to_string())
        }
    })
}

fn required_path(key: &str, default: &str) -> anyhow::Result<PathBuf> {
    env_path_or_default(key, PathBuf::from(default))
}

fn env_path_or_default(key: &str, default: PathBuf) -> anyhow::Result<PathBuf> {
    let raw = env::var(key).unwrap_or_else(|_| default.display().to_string());
    let path = PathBuf::from(raw);
    if path.as_os_str().is_empty() {
        return Err(anyhow!("{key} resolved to an empty path"));
    }
    Ok(path)
}

fn parse_bool(value: &str) -> anyhow::Result<bool> {
    match value.trim().to_ascii_lowercase().as_str() {
        "1" | "true" | "yes" | "on" => Ok(true),
        "0" | "false" | "no" | "off" => Ok(false),
        _ => Err(anyhow!("cannot parse boolean value '{value}'")),
    }
}
