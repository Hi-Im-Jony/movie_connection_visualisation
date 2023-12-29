import pandas as pd
import json
NUM_MOVIES = 10
class Person:
    def __init__(self, name: str, gender: int, actor: bool = True):
        self.name = name
        self.gender = gender
        self.actor = actor
        self.movies = []
        self.connections = []

class Movie:
    def __init__(self, name: str, id: str, budget: int, studio: str, rating: float, release_date: str, genre: [str], 
                 actors:[Person] = [], directors: [] = []):
        self.name = name
        self.id = id
        self.budget = budget
        self.studio = studio
        self.rating = rating
        self.release_date = release_date
        self.genre = genre
        self.actors = actors
        self.directors = directors

def filter_movies(movies_df: pd.DataFrame):
    movies_df = movies_df[movies_df['budget'] != '0']
    return movies_df

def create_movie_list(movies_df: pd.DataFrame):
    random_sample = movies_df.sample(n=NUM_MOVIES)
    movies = []
    for _, movie_row in random_sample.iterrows():
        pass
    return random_sample

def create_person_list(movies_df: pd.DataFrame, credits_df: pd.DataFrame):
    persons = []
    
    for _, movie in movies_df.iterrows():
        actors = parse_actors(movie['cast'])

def parse_actors(cast_json_str):
    try:
        cast_list = json.loads(cast_json_str)
        actors = [{"name": actor["name"], "gender": actor["gender"]} for actor in cast_list]
        return actors
    except json.JSONDecodeError:
        return []

def parse_directors(crew_json_str):
    try:
        crew_list = json.loads(crew_json_str)
        directors = [{"name": member["name"], "gender": member["gender"]} 
                     for member in crew_list if member["job"] == "Director"]
        return directors
    except json.JSONDecodeError:
        return []

def get_movie(movie_id, movies_df):
   return movies_df[movies_df['id']==str(movie_id)]

def convert_to_number(s):
    try:
        # Convert the string to a float, which automatically handles scientific notation
        return str(float(s))
    except ValueError:
        # In case the string is not a valid number, return an error message
        return str(float(0))


credits_csv_path = 'data/tmdb_5000_credits.csv'
credits_columns = ["movie_id", "title", "cast", "crew"]
credits_df = pd.read_csv(credits_csv_path, names=credits_columns)

movies_csv_path = 'data/tmdb_5000_movies.csv'
movies_original_columns = ["budget", "genres", "homepage", "movie_id", "keywords", "original_language", "original_title", "overview", "popularity", "production_companies", "production_countries", "release_date", "revenue", "runtime", "spoken_languages", "status", "tagline", "title", "vote_average", "vote_count"]
movies_columns_to_keep = ["movie_id", "budget", "genres", "overview", "production_companies", "release_date", "revenue", "vote_average"]
df = pd.read_csv(movies_csv_path, names=movies_original_columns)
df  = df[movies_columns_to_keep]

movies_df = pd.merge(df, credits_df, on='movie_id')
movies_df = movies_df[movies_df['budget'] != '0']

movies_df = movies_df[movies_df['revenue'] != '0']
movies_df['budget'] = movies_df["budget"].apply(convert_to_number)
movies_df['actors'] = movies_df['cast'].apply(parse_actors)
movies_df['directors'] = movies_df['crew'].apply(parse_directors)
movies_df.drop(columns=['crew', 'cast'])
movies_df.to_csv("data/movies.csv", index=False)
