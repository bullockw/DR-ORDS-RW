# Disaster Recovery with ORDS

Disaster Recovery Network and connectivity setup
=======================================================

This solution provides a Network Architecture deployment to demonstrate Disaster Recovery scenario across 2 regions [ examples are geared towards region Montreal & Toronto and can be used for any OCI regions].


## Quickstart Deployment
### Prerequisites
1. Clone this repository to your local host. The `DR-ORDS-RW` directory contains the Terraform configurations for a sample topology based on the architecture described earlier.
    ```
    git clone https://github.com/Chavez-Saul/DR-ORDS-RW.git
    ```

2.  Create your own private/public key pair on your local system.
3.  Zip up all of the files in to a zip folder. The zip file name is not important.
    Just make sure it has the follow structure.
    
        rackware/
        ├── data_sources.tf
        ├── dr-ords-schema.yaml
        ├── main.tf
        ├── modules
        │   ├── bastion_instance
        │   │   ├── main.tf
        │   │   ├── outputs.tf
        │   │   └── variables.tf
        │   ├── dbaas
        │   │   ├── main.tf
        │   │   ├── outputs.tf
        │   │   └── variables.tf
        │   ├── network
        │   │   ├── main.tf
        │   │   ├── outputs.tf
        │   │   └── variables.tf
        │   └── ords
        │       ├── main.tf
        │       ├── outputs.tf
        │       ├── README.md
        │       ├── remote-exec.tf
        │       └── variables.tf
        ├── outputs.tf
        ├── providers.tf
        ├── terraform.tfvars
        ├── userdata
        │   ├── bootstrap.sh
        │   ├── files_init
        │   │   └── config_init.sh
        │   ├── files_init.zip
        │   ├── files_jetty
        │   │   ├── apex_add_db.sh
        │   │   ├── apex_inst_check.sql
        │   │   ├── apex_setup_base.exp
        │   │   ├── config_apex1.sql
        │   │   ├── config_apex2.sql
        │   │   ├── config_cert.sh
        │   │   ├── config_jetty_apex.sh
        │   │   ├── config_jetty_ca-ssl.sh
        │   │   ├── config_jetty_init.sh
        │   │   ├── config_jetty_ords.sh
        │   │   ├── dns_ocidns.sh
        │   │   ├── ords_add_db.sh
        │   │   ├── ords_pu_check.sql
        │   │   ├── ords_setup_base.exp
        │   │   ├── ords_validate_base.exp
        │   │   ├── pw_prof_chk.sql
        │   │   ├── pw_verify_base.sql
        │   │   ├── pw_verify_null.sql
        │   │   ├── start_ords.sh
        │   │   └── stop_ords.sh
        │   └── files_jetty.zip
        └── variables.tf

4. Make sure to create a public bucket in object storage. Then upload apex.zip and the ords.war file to the bucket.
    The apex.zip file can be downloaded using the following link [apex](https://www.oracle.com/tools/downloads/apex-downloads.html). 
    The ords.war file can be downloaded using the following link [ords](https://www.oracle.com/database/technologies/appdev/rest-data-services-downloads.html)
    ![](rackwaresaleplay/Objectstorage.PNG)
    
5. Navigate to the resource manager tab in OCI. Then create a new stack to import the zip file.
    
    1. Import the zip file into the stack 
    ![](rackwaresaleplay/ResourceManager.PNG)
    
    2. Input the configuration for the instances.
    ![](rackwaresaleplay/ResourceManager-Input-Basic.PNG)
    
    3. Input the configuration for the vcn.
    ![](rackwaresaleplay/ResourceManager-Network.PNG)
    
    4. Copy your public and private key. Make sure you are using the correct format.
    ![](rackwaresaleplay/ResourceManager-Keys.PNG)
    
    5. Input the configuration for the object storage.
    ![](rackwaresaleplay/ResourceManager-ObjectStorage.PNG)
    
    6. Review 
    ![](rackwaresaleplay/ResourceManager-Review.PNG)
    
    ### Plans

    1.  Select plan from the dropdown menu.
    ![](rackwaresaleplay/ResourceManager-Plan-2.PNG)
    
    2.  Make sure everything looks okay and then proceed
    ![](rackwaresaleplay/ResourceManager-Plan-3.PNG)
    
    3.  Wait unitl the plan is green.
    ![](rackwaresaleplay/ResourceManager-Plan-4.PNG)
    
    ### Apply
    
    1.  Select plan from the dropdown menu.
    ![](rackwaresaleplay/ResourceManager-Apply-1.PNG)
    
    2.  Wait unitl the plan is green.
    ![](rackwaresaleplay/ResourceManager-Apply-2.PNG)

    ### Destroy
6.  First navigate to OCI Console and terminate the Standby database and once the termination is successfull then run the following command


## Troubleshooting
   A possible issue you make face is not having enough resources. Test to make sure 
   that you can create a drg manual in both regions you want to deploy the resources
   in.

### End