
# Web App for Containers quick start docker images

This repo contains all currently quick start docker images contributed by the community.	

## Contribution guide

Please follow the guidelines to be compliant . If any docker image is out of compliance , it will be **blacklisted** from this repo and eventually removed. 

## Files, folders and naming conventions
1. Create a new folder for a new docker image and include a version folder . Such as 
```
+my-image
	         \  0.1 
		       \Dockerfile and other files 
		
```
 
 *Note:  If you are updating an existing image  , create a new version folder within your image folder.*
  
2.Must include a README.md within version folder to describe :
		a. Any changes with deployment of use of the image 
		b. Include comments if the image is not backward compatible and how user can manually upgrade to new version 

+ [**Submission Work Flow**](/contribution-guide/submissionvalidation.md). The sequence diagram of submission validation work flow.
+ [**Best practices**](/contribution-guide/best-practices.md). Best practices for improving the quality of your docker image
+ [**Git tutorial**](/contribution-guide/git-tutorial.md). Step by step to get you started with Git.
+ [**Useful Tools**](/contribution-guide/useful-tools.md). Useful resources and tools for docker image development

## Submission workflow 

The submission process as shown below: 

1. Fork the github repostiory
2. Checkout branch build-test
3. pull changes from build-test branch
4. create a new branch or use build-test branch
5. Commit your changes to the forked repository 
6. Push changes to forked repository
7. Send a PR ONLY to build-test branch of main repository
8. Automated Travis CI will run to validate the PR 
9. If build fails , fix the issues and commit changes to the same PR 
10. if build passes  the reviewers for the PR will manual verfiy and provide guidance 
11. PR is merged to build-test branch in main repo by repo reviewers 
12. Repo reviewers (Owner) will run sanity test on web app for containers 
13. If the image has no issues it will be merged into master 
14. Image will be deployed to Docker hub 

The time taken to approve or reject a PR can vary as this is community driven. 

**Please submit PR to build-test branch ONLY . Any PR directly submitted to master from a contributor will be rejected.** 
![Submission workflow for docker images](images/work-flow.png) 

- Owner  : The team of members who maintain this repository and review, merge pull requests contributed to the repo.
- Submitter : Contributor member of one or more docker images on this repository 


### Guidance on setting tags during *Automated Deployment to Docker hub* step:

The related image would be deployed to Docker hub automatically as soon as commit message include string "#sign-off". 
Below 2 kinds of tags would be set.
1. Set tag as the value of version folder name. For example:
```
Update files which under ..\my-image\0.1, 
it would push my-image:0.1 to Docker hub.
```
2. Set tag as "latest".
- There is 1 file names latest.txt exist under image folder.
- The value of above file is as same as the related image version.
For example: 
```
Update files which under ..\my-image\0.1, 
..\my-image\latest.txt is exist and the content is "0.1", 
it would also push my-image:latest to Docker hub.
```

## Deploying Samples
You can deploy these samples directly through the Azure Portal

1. Go to [Azure portal](https://portal.azure.com)
2. Search for [Web app for Containers](https://portal.azure.com#create/microsoft.appsvclinux)
3. Enter web app name , susbcription , resource group 
4. Select configure container and enter the docker hub image name with the tag name. you can find all the docker hub images [here](https://hub.docker.com/r/appsvcorg) 
5. Review the readme.md for the imae you are using to make sure any additional configuration such as app settings need to be updated. Make the necessary changes 
6. Now browse the application 

*Note: The first request can take longer to complete since the docker image needs to be pulled and run on the container for the first request. This can occur when you scale up your application or the instance gets recycled.*


