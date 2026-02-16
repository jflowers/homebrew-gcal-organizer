class GcalOrganizer < Formula
  desc "Automate meeting note organization, calendar syncing, and task assignment"
  homepage "https://github.com/jflowers/gcal-organizer"
  url "https://github.com/jflowers/gcal-organizer/archive/refs/tags/v1.2.4.tar.gz"
  sha256 "f1026cf9f71f029154b680a5075c440200a4bb6579390be99256f7e0175029b5"
  license "MIT"

  bottle do
    root_url "https://github.com/jflowers/gcal-organizer/releases/download/v1.2.4"
    sha256 cellar: :any_skip_relocation, arm64_sonoma: "c1842a12f5b2bea2d9ae2d99ad74c2e3d62734269cc5030ddef284ab84819a0e"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "251f0122aa525fe817589de107d55a2d950bc597c0290b565cbf5f2497c7bd2e"
  end
  head "https://github.com/jflowers/gcal-organizer.git", branch: "main"

  depends_on "go" => :build
  depends_on "node" # Required for browser-based task assignment (Playwright)

  def install
    # Build the Go binary
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.Version=v#{version}"), "./cmd/gcal-organizer"

    # Install man page
    man1.install "man/gcal-organizer.1"

    # Install browser automation scripts
    (libexec/"browser").install Dir["browser/*"]

    # Install service wrapper
    (libexec/"deploy").install "deploy/run-wrapper.sh"
    chmod 0755, libexec/"deploy/run-wrapper.sh"

    # Install browser dependencies
    cd libexec/"browser" do
      system "npm", "install", *std_npm_args(prefix: false)
    end
  end

  def post_install
    # Config directory is created by 'gcal-organizer init'
  end

  def caveats
    <<~EOS
      To get started:

        1. Run the setup wizard:
           gcal-organizer init

        2. Download Google Cloud credentials (see output from init)

        3. Authenticate:
           gcal-organizer auth login

        4. Set up browser automation (for task assignment):
           gcal-organizer setup-browser

        5. Check everything is configured:
           gcal-organizer doctor

        6. Test with dry-run:
           gcal-organizer run --dry-run

        7. Install the hourly service:
           gcal-organizer install

      Manage the service with:
        gcal-organizer doctor     # check system health
        gcal-organizer uninstall  # remove the service

      Man page: man gcal-organizer
    EOS
  end

  test do
    # Verify binary runs and shows help
    assert_match "gcal-organizer", shell_output("#{bin}/gcal-organizer --help")

    # Verify version or subcommands exist
    assert_match "doctor", shell_output("#{bin}/gcal-organizer --help")
    assert_match "setup-browser", shell_output("#{bin}/gcal-organizer --help")

    # Verify init runs without error in non-interactive mode
    system "#{bin}/gcal-organizer", "init", "--non-interactive"
  end
end
