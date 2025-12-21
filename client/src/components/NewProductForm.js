import React from 'react';
// import {v4} from 'uuid';
import PropTypes from 'prop-types';
import ReusableForm from './ReusableForm';

function NewProductForm (props) {
    

    // function onFileChange(event){
    //     // console.log(event.target.files[0])
    //     // const file=  event.target.files[0]
        

    //     props.onPhotoUpload({
    //         file: event.target.files[0]
    //     })
    // }

    async function handleNewProductFormSubmission(event){
        event.preventDefault();

        // Check for selected file
        const fileInput = event.target.photo;
        let photoUrl = '';

        if(fileInput && fileInput.files && fileInput.files[0]){
            const file = fileInput.files[0];
            const formData = new FormData();
            formData.append('image', file);

            try{
                const res = await fetch('/api/products/upload', {
                    method: 'POST',
                    body: formData
                });
                const data = await res.json();
                if(res.ok){
                    photoUrl = data.imageUrl; // e.g. /images/filename.png
                } else {
                    console.error('Image upload failed', data);
                }
            }catch(err){
                console.error('Upload error', err);
            }
        }

        props.onNewProductCreation({
            name: event.target.name.value,
            price: event.target.price.value,
            description: event.target.description.value,
            quantity: event.target.quantity.value,
            photo: photoUrl
        });
    }
   
    return (
        <React.Fragment>
            <div className="container product-form">
                <ReusableForm 
                formSubmissionHandler ={handleNewProductFormSubmission}
                buttonText = 'Add Product' />
            </div>
        </React.Fragment>
    )
    
}

NewProductForm.propTypes = {
    onNewProductCreation: PropTypes.func
}

export default NewProductForm;
