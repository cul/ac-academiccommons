# Academic Commons API v1
- [Search Records](#search-records)
- [Facets](#facets)
- [Records](#records)

## Search Records
Query to conduct searches for Academic Commons records. The type of search can be specified with each query, in most cases a keyword search should be sufficient. The purpose of this endpoint is to provide a wrapper around our most commonly used searching capabilities.

```
GET /api/v1/search/:search_type
```
`search_type`: Optional path parameter. Describes the type of search to be conducted. A `keyword` search searches all fields, while all the other searches only search in specific fields. A `keyword` search is conducted by default if none is specified. Can be one of `keyword`, `title`, or `subject`.

### Parameters
All these parameters are optional.

| Parameter | Default     | Description     |
|:---------:|:-----------:|-----------------|
|`q`        | _(none)_    | query string    |
|`{value}[]`| _(none)_    | filters applied to query, should be described as an array; [valid filters](filters-facets)<br/>ex: `?department[]=Computer Science` |
|`page`     | `1`         | page number of results; must be an integer |
|`per_page` | `25`        | number of results returned per page; the maximum number of results is 100 |
|`format`   | `json`      | format of response; [valid formats](formats) |
|`sort`     | `best_match` | sorting of search results; [valid sort](sort) |
|`order`    | `desc`      | ordering of results; should be `asc` or `desc`; still considering other options for sorting/ordering |


##### Filters/Facets
Fields that can be facetted/filtered by:
- `author`
- `author_id` _(author_uni)_
- `date` _(might need to add faceting by date range)_
- `department`
- `subject`
- `type`
- `series`

##### Sort
- `best_match`: sorting by relevance of search result, followed by creation date
- `date`: sorting by publication date
- `title`: sorting alphabetically by title
- `created_at`: sorting by date the record was created in our system

##### Formats
- `json`
- `rss` (only available for `/search` requests)
- `atom` _(tentative)_

### Successful Response
#### Headers
```
Link:
  <https://academiccommons.columbia.edu/api/v1/search/keyword?q=global&department[]=Computer+Science&page=2>; rel="next",
  <https://academiccommons.columbia.edu/api/v1/search/keyword?q=global&department[]=Computer+Science&page=12>; rel="last";
api version header (tentative)
content type header (if needed)
```

#### Code
```
200
```

#### Body

##### _JSON_
A _json_ response will contain the number of results, page number, query parameters, records and some facets. This request will only return up to five facets for each field. For more facets there will need to be a subsequent query to `/facets`. The persistent_url should be used when linking to this resource.

```json
{
  "total_number_of_results": 300,
  "page": 1,
  "per_page": 25,
  "params": {
    "search_type": "keyword",
    "q": "global",
    "sort": "best_match",
    "filters": {
      "department": ["Computer Science"]
    }
  },

  "records": [
    {
      "id": "10.7916/D82J6QBM",
      "legacy_id": "ac:ksn02v6wz7",
      "title": "Approximating a Global Passive Adversary Against Tor",
      "authors": ["Chakravarty, Sambuddho", "Stavrou, Angelos", "Keromytis, Angelos D."],
      "abstract": "We present a novel, practical, and effective mechanism for identifying the IP address of Tor clients. We approximate an almost-global passive adversary (GPA) capable of eavesdropping anywhere in the network by using LinkWidth, a novel bandwidth-estimation technique.",
      "departments": ["Computer Science", "Engineering"],
      "date": 2008,
      "subjects": ["Computer science", "Computer networks", "Computer networks--Security measures"],
      "genre": ["Reports"],
      "persistent_url": "https://doi.org/10.7916/D82J6QBM",
      "created_at": "2018-01-19T14:19:26+00:00"
    },

    ...

  ],

  "facets": {
    "departments": {
      "Computer Science": 142,
      "Engineering": 39
    },
    "subjects": {
      "Computers": 2
    }
  }
}
```

##### _RSS_
A _rss_ response would return a link to the search and contains an xml/rss serialization of each record. Multiple authors are separated by `;`. Multiple subjects, departments and types are separated by `,`. Because of the limitations of the rss specification this format will not display facets and other details shown in the json serialization. The guid should be used when linking to any resource.


```xml
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1" xmlns:vivo="http://vivoweb.org/ontology/core">
  <channel>
    <title>Academic Commons Search Results</title>
    <link>https://academiccommons.columbia.edu/api/v1/search?format=rss&q=global&department[]=Computer+Science</link>
    <description>Academic Commons Search Results</description>
    <language>en-us</language>
    <item>
      <title>Approximating a Global Passive Adversary Against Tor</title>
      <link>https://academiccommons.columbia.edu/catalog/ac:ksn02v6wz7</link>
      <dc:creator>Chakravarty, Sambuddho; Stavrou, Angelos; Keromytis, Angelos D.</dc:creator>
      <guid>https://doi.org/10.7916/D82J6QBM</guid>
      <pubDate>Fri, 15 Dec 2017 16:10:28 -0500</pubDate>
      <dc:date>2008<dc:date>
      <description>We present a novel, practical, and effective mechanism for identifying the IP address of Tor clients. We approximate an almost-global passive adversary (GPA) capable of eavesdropping anywhere in the network by using LinkWidth, a novel bandwidth-estimation technique.</description>
      <dc:subject>Computer science, Computer networks, Computer networks--Security measures</dc:subject>
      <dc:type>Reports</dc:type>
      <vivo:Department>Computer Science, Engineering</vivo:Department>
    </item>

    ...

  </channel>
</rss>
```

### Examples
#### RSS feed with an author's publication in descinding order
`GET /api/v1/search?author_id[]=abc123&format=rss&sort=date&per_page=100`

_Response_

_Body_
```xml
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1" xmlns:vivo="http://vivoweb.org/ontology/core#">
  <channel>
    <title>Academic Commons Search Results</title>
    <link>https://academiccommons.columbia.edu/api/vi/search?author_id[]=abc123&format=rss&sort=created_at&per_page=100</link>
    <description>Academic Commons Search Results</description>
    <language>en-us</language>
    <item>
      <title>Example Article Two</title>
      <link>https://academiccommons.columbia.edu/catalog/ac:test1</link>
      <dc:creator>Doe, John; Doe, Jane</dc:creator>
      <guid>https://doi.org/10.791875/H73943034</guid>
      <pubDate>Fri, 15 Dec 2017 16:10:28 -0500</pubDate>
      <dc:date>2008<dc:date>
      <description>Sed faucibus eleifend pellentesque. Nulla facilisi. Suspendisse rutrum sit amet magna quis egestas. Suspendisse vitae felis vitae neque luctus laoreet. Integer congue maximus pharetra. Phasellus laoreet sem quam, et porttitor quam auctor sit amet. Sed vitae erat a enim commodo porttitor eu ac dolor.</description>
      <dc:subject>Computer science, Computer networks, Testing</dc:subject>
      <dc:type>Article</dc:type>
      <vivo:Department>Computer Science, Engineering</vivo:Department>
    </item>
    <item>
      <title>Example Article One</title>
      <link>https://academiccommons.columbia.edu/catalog/ac:test2</link>
      <dc:creator>Chakravarty, Sambuddho; Stavrou, Angelos; Keromytis, Angelos D.</dc:creator>
      <guid>https://doi.org/10.7916/D82J6QBM</guid>
      <pubDate>Fri, 15 Dec 2017 16:10:28 -0500</pubDate>
      <dc:date>2002<dc:date>
      <description>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc consequat lectus sit amet nulla dignissim, nec tempor mi vehicula. Fusce dolor nulla, congue ac aliquam et, lobortis at lacus. Praesent semper neque sit amet velit malesuada, non laoreet nulla pulvinar. Cras vehicula ligula et hendrerit ornare. Sed scelerisque odio nec purus suscipit interdum. Fusce sed augue vulputate, rhoncus tellus sit amet, lobortis ex. Sed diam arcu, aliquet quis sapien posuere, aliquet efficitur diam. Vivamus tristique, diam malesuada auctor cursus, erat sem ullamcorper risus, ut euismod erat lectus ac justo. Sed vel eros aliquam, rutrum arcu quis, commodo nibh. Nunc eget tincidunt lacus. In vel lectus sed nisi cursus dapibus. Quisque fermentum dolor ac nisl ullamcorper, vel ornare orci aliquam.</description>
      <dc:subject>Computer science, Testing</dc:subject>
      <dc:type>Article</dc:type>
      <vivo:Department>Computer Science, Engineering</vivo:Department>
    </item>

    ...

  </channel>
</rss>
```

## Facets (tentative)
Returns all possible facets for a subset of results.
```
GET /api/v1/facets
```

Returns all possible facets for one field.
```
GET /api/v1/facets/:field
```

## Record (tentative)
Returns full representation of record, not just basic fields. Essentially a json representation of the record.
```
GET /api/v1/record/:id
```
_NOTE: `:id` should probably be DOI_
