const hideOrShowMinVectorSimilarityInputBasedOnSelectedSearchField = () => {
  const minVectorSimilarityInput = document.querySelector('#min_vector_similarity');
  const minVectorSimilarityLabel = document.querySelector('[for="min_vector_similarity"]');
  if (minVectorSimilarityInput) {
    const searchFieldInput = document.querySelector('#search_field');
    if (searchFieldInput) {
      minVectorSimilarityInput.style.display = searchFieldInput.value === 'keyword' ? "none" : "block";
      minVectorSimilarityLabel.style.display = searchFieldInput.value === 'keyword' ? "none" : "block";
    }
  }
};

document.addEventListener('turbo:load', () => {
  // Immediately hide or show min vector similarity input on page load
  hideOrShowMinVectorSimilarityInputBasedOnSelectedSearchField();

  // Bind change listener to search field so that we can hide or show the min
  // vector similarity input based on changes to the selected search field.
  document.querySelector('#search_field').addEventListener('change', () => {
    hideOrShowMinVectorSimilarityInputBasedOnSelectedSearchField();
  })
});
