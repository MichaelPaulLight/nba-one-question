# Make the project's R/ helpers available to every test.
for (f in list.files(test_path("..", "..", "R"), pattern = "\\.R$", full.names = TRUE)) {
  source(f)
}
