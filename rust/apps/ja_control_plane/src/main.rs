#[tokio::main]
async fn main() -> anyhow::Result<()> {
    ja_control_plane::run_cli().await
}
