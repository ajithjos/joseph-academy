#[tokio::main]
async fn main() -> anyhow::Result<()> {
    control_plane::run_cli().await
}
