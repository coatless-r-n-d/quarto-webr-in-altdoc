

## Integrating {quarto-webr} with {altdoc} through {quarto-panelize}

In this experiment, we’ll cover how to incorporate interactive code
cells on an R package documentation website powered by
[`{altdoc}`](https://altdoc.etiennebacher.com/#/). We’ll use
[`{quarto-panelize}`](https://github.com/coatless-quarto/panelize) to
create a tabset panel that includes both static and interactive examples
from the R package. The interactive examples will be powered by the
community [`{quarto-webr}`](https://github.com/coatless/quarto-webr/)
extension, which acts as an interface for Quarto into the main
[webR](https://docs.r-wasm.org/webr/latest/) project. We’ll use a
developmental R package webR binary based off the latest commit of the
repository through [`{rwasm}`](https://github.com/r-wasm/rwasm).
Finally, we’ll deploy both to GitHub Pages using GitHub Actions to
demonstrate the capabilities of the integration.

You can see examples of the documentation pages on the [live
website](https://rd.thecoatlessprofessor.com/quarto-webr-in-altdoc) by
expanding **References** section on the left side of the documentation
page:

- Function page:
  [`in_webr()`](https://rd.thecoatlessprofessor.com/quarto-webr-in-altdoc/man/in_webr.html)
- Data page:
  [`residual_surrealism`](https://rd.thecoatlessprofessor.com/quarto-webr-in-altdoc/man/residual_surrealism.html)

### Step 0: Have R Package with a GitHub Repository

Ensure that you have an R package with a GitHub repository.

### Step 1: Setup {altdoc}

1.  Install the [`{altdoc}`](https://altdoc.etiennebacher.com/#/)
    package from CRAN:

``` r
install.packages("altdoc")
```

2.  Create a new `{altdoc}` documentation project that uses Quarto
    websites:

``` r
altdoc::setup_docs(tool = "quarto_website")
```

### Step 2: Add the `{quarto-webr}` and `{quarto-panelize}` extension

1.  Install the `{quarto-webr}` and `{quarto-panelize}` extensions by
    typing the following into Terminal:

``` sh
quarto add coatless/quarto-webr
quarto add coatless-quarto/panelize
```

2.  Move the extensions to the `altdoc` directory:

``` sh
mv _extensions altdoc/_extensions
```

> [!IMPORTANT]
>
> The version of `{quarto-webr}` differs from the main repository
> slightly to put the version of webR on the `latest` version instead of
> `v0.3.3` as the [`{rwasm}`](https://github.com/r-wasm/rwasm) package
> used to compile binaries is now obtaining one for R v4.4.0 instead of
> R v4.3.3.

### Step 3: Add a pre-render step to `quarto_website.yaml` file

1.  Add a [`pre-render`
    step](https://quarto.org/docs/projects/scripts.html#pre-and-post-render)
    into the [Quarto Project
    file](https://quarto.org/docs/projects/quarto-projects.html#project-metadata)
    that includes an [R
    script](altdoc/panelize-code-cells-for-quarto-webr.R) to reformat
    the code cells.

``` yaml
project:
  type: website
  pre-render: panelize-code-cells-for-quarto-webr.R
```

> [!NOTE]
>
> This ensures that the intermediary content changes without needing
> manual function modifications in the altdoc.

You can find this R script here:

<https://github.com/coatless-r-n-d/quarto-webr-in-altdoc/blob/main/altdoc/panelize-code-cells-for-quarto-webr.R>

### Step 5: Update Quarto extension configuration in `quarto_website.yaml`

Later in the `quarto_website.yaml` file, we need to register the
extensions by specifying the `filters` key and the extensions to use.
Additionally, we set options globally to load the developmental R
package binary.

``` yaml
# Add custom repository registration
webr:
  packages: ['$ALTDOC_PACKAGE_NAME']
  repos:
    - $ALTDOC_PACKAGE_URL
    
# Attach extensions
filters:
- panelize
- webr
```

### Step 6: Make sure the `DESCRIPTION` file has the correct `URL` field

Ensure that the first URL in the `URL` field in the `DESCRIPTION` file
points to the GitHub Pages location. This is necessary for the
`{quarto-webr}` extension to automatically find the correct location for
the developmental R package binary for webR.

For example, we would want the GitHub Pages given by:

``` default
https://<github-username>.github.io/<repository>
```

where `<github-username>` is the GitHub username and `<repository>` is
the repository.

For example, this repository could be specified as:

``` default
URL: https://coatless-r-n-d.github.io/quarto-webr-in-altdoc, https://github.com/coatless-r-n-d/quarto-webr-in-altdoc
```

> [!IMPORTANT]
>
> Failure to setup this portion will require manual intervention in the
> interactive code tab to specify the location of the R package binary
> for webR to install via `install.packages()` or `webr::install()`.

### Step 7: Setup GitHub Actions for `{altdoc}` and `{rwasm}`

We’ll need to modify the GitHub actions workflow that is created by the
[`altdoc::setup_github_actions()`](https://altdoc.etiennebacher.com/#/man/setup_github_actions.md)
to incorporate a step to build the R package binary for webR.

``` yaml
# Workflow derived from https://github.com/r-lib/actions/tree/v2/examples
# Need help debugging build failures? Start at https://github.com/r-lib/actions#where-to-find-help
on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]
  release:
    types: [published]
  workflow_dispatch: {}

name: altdoc

jobs:
  rwasmbuild:
    # Only restrict concurrency for non-PR jobs
    concurrency:
      group: altdoc-webr-${{ github.event_name != 'pull_request' || github.run_id }}
    env:
      GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}
    permissions:
      contents: write
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        
      # Build the local R package and structure the CRAN repository
      - name: Build WASM R packages
        uses: r-wasm/actions/build-rwasm@v1
        with:
          packages: "."
          repo-path: "_site"
      
      # Upload the CRAN repository for use in the next step
      # Make sure to set a retention day to avoid running into a cap
      - name: Upload build artifact
        uses: actions/upload-artifact@v3
        with:
          name: rwasmrepo
          path: |
            _site
          retention-days: 1

  altdoc:
    runs-on: ubuntu-latest
    # Add a dependency on the prior job completing
    needs: rwasmbuild
    # Required for the gh-pages deployment action
    environment:
      name: github-pages
    env:
      GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}
    permissions:
      # To download GitHub Packages within action
      repository-projects: read
      # For publishing to pages environment
      pages: write
      id-token: write
    steps:
      - uses: actions/checkout@v4

      - uses: quarto-dev/quarto-actions/setup@v2

      - name: Get Script
        run: curl -OLs https://eddelbuettel.github.io/r-ci/run.sh && chmod 0755 run.sh

      - name: Bootstrap
        run: ./run.sh bootstrap

      - name: Dependencies
        run: ./run.sh install_all

      - name: Build site
        run: |
          # If parallel = TRUE in render_docs()
          # future::plan(future::multicore)
          install.packages(".", repos = NULL, type = "source")
          install.packages("pkgload")
          pkgload::load_all()
          altdoc::render_docs(parallel = FALSE, freeze = FALSE)
        shell: Rscript {0}
        
      - name: Copy to new directory
        run: |
          cp -r docs _site
        
      # New material ---
      
      # Download the built R WASM CRAN repository from the prior step.
      # Extract it into the `_site` directory
      - name: Download build artifact
        uses: actions/download-artifact@v3
        with:
          name: rwasmrepo
          path: _site
      
      # Upload a tar file that will work with GitHub Pages
      # Make sure to set a retention day to avoid running into a cap
      # This artifact shouldn't be required after deployment onto pages was a success.
      - name: Upload Pages artifact
        uses: actions/upload-pages-artifact@v2
        with: 
          retention-days: 1
      
      # Use an Action deploy to push the artifact onto GitHub Pages
      # This requires the `Action` tab being structured to allow for deployment
      # instead of using `docs/` or the `gh-pages` branch of the repository
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v2
```

You can view the full workflow file here:

<https://github.com/coatless-r-n-d/quarto-webr-in-altdoc/blob/main/.github/workflows/altdoc.yaml>

### Step 8: Enable GitHub Pages

Enabling GitHub Pages on the repository by following:

1.  Click on the **Settings** tab for the repository
2.  Under “Code and automation”, select the **Pages** menu item.
3.  Under the “Source” option select **GitHub Actions** from the drop
    down.
4.  In the “Custom Domain” settings, make sure that **Enforce HTTPS** is
    checked.

## Fin

Woah! That’s a lot of information. In short, we’ve covered how to
integrate interactive R code cells on an R package documentation website
powered by `{altdoc}`. We’ve smashed the barrier of entry for being able
to provide interactive examples has been lowered. This is a great way to
provide a more engaging experience for users of your R package.

Feel free to check the live demo and source code for more details.

- [Source Code](https://github.com/coatless-r-n-d/quarto-webr-in-altdoc)
- [Live
  Demo](https://rd.thecoatlessprofessor.com/quarto-webr-in-altdoc/man/in_webr.html)

## Acknowledgements

This experiment greatly benefited from insights gleaned from discussing
the use of extensions and pre-render scripts on the [`{altdoc}` issue
tracker](https://github.com/etiennebacher/altdoc/issues/253) and with
the Quarto developer team on different ways to approach handle cell
changes.
