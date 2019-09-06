### Changelog
- Add your list of changes here 

## Please agree to guidelines below
Review and check the following guidelines before submitting a PR.
1. Include a README.md within version folder to describe :
	a. Any changes with deployment of use of the image 
	b. Include comments if the image is not backward compatible and how user can manually upgrade to new version 
2. SSH support included in the docker image.
3. Do no use VOLUME with the docker image since it is not supported 
4. Use only ONE external port in addition to SSH port 2222
5. Do not use chown (recursive) statements with the docker image 

Please check both statements below to agree our contribution policies. 
[ ] - I have submitted the PR if you've read through the Contribution Guide and best practices checklist.
[ ] - I certify that the Docker image was tested successfully at runtime using Web App for Containers or Linux Web App.


## Pull Request Type
What kind of change does this Pull Request introduce? Please check the one that applies to this PR using "x".
- [ ] New Docker image version 
- [x] BugFix in existing docker image 
- [x] Code style formatting 
- [ ] Documetation/Readme updates 
- [ ] Other . Please describe : .....