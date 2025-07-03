# DATASCIENTEST JENKINS EXAM
# python-microservice-fastapi
Learn to build your own microservice using Python and FastAPI

## How to run??
 - Make sure you have installed `docker` and `docker-compose`
 - Run `docker-compose up -d`
 - Head over to http://localhost:8080/api/v1/movies/docs for movie service docs 
   and http://localhost:8080/api/v1/casts/docs for cast service docs

## Jenkins Pipeline Configuration
- **Important**: Jenkins’s Pipeline definition (in the job’s SCM settings) will fetch whichever branch you’ve specified there—by default it’s `master`.  
  Even if you push `master` locally, if the job is pointed at a repo that has no `master` branch (or its default is `main`), you’ll see the “couldn't find remote ref refs/heads/master” error.  
- To fix this, edit your Jenkins job → Pipeline → Branch Specifier (under SCM) and set it to:
  ```
  */main
  ```
  or whatever branch name actually exists in your remote repository.
